module ScimRails
  class ScimGroupsController < ScimRails::ApplicationController

    def index
      Rails.logger.warn("ScimRails::ScimGroupsController: index: request.original_url #{request.original_url} request.params: #{params.to_json}")
      if params[:filter].present?
        query = ScimRails::ScimQueryParser.new(params[:filter])

        groups = @company
                   .public_send(ScimRails.config.scim_groups_scope)
                   .where(
                     "#{ScimRails.config.scim_groups_model.connection.quote_column_name(query.attribute)} #{query.operator} ?",
                     query.parameter
                   )
                   .order(ScimRails.config.scim_groups_list_order)
      else
        groups = @company
                   .public_send(ScimRails.config.scim_groups_scope)
                   .order(ScimRails.config.scim_groups_list_order)
      end

      counts = ScimCount.new(
        start_index: params[:startIndex],
        limit: params[:count],
        total: groups.count
      )

      json_scim_response(object: groups, counts: counts)
    end

    def create
      Rails.logger.warn("ScimRails::ScimGroupsController: create: request.original_url #{request.original_url} request.params: #{params.to_json}")
      ScimRails.config.scim_group_create_guard.call(@company, params) if ScimRails.config.scim_group_create_guard.is_a?(Proc)

      display_name_key = ScimRails.config.queryable_group_attributes[:displayName]
      find_by_display_name = Hash.new
      find_by_display_name[display_name_key] = permitted_group_params[display_name_key]
      group = @company.public_send(ScimRails.config.scim_groups_scope).find_or_initialize_by(find_by_display_name)
      group.public_send(ScimRails.config.group_create_method, permitted_group_params)
      json_scim_response(object: group, status: :created)
    end

    def show
      Rails.logger.warn("ScimRails::ScimGroupsController: show: request.original_url #{request.original_url} request.params: #{params.to_json}")
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])
      json_scim_response(object: group)
    end

    def put_update
      Rails.logger.warn("ScimRails::ScimGroupsController: put_update: request.original_url #{request.original_url} request.params: #{params.to_json}")
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])
      group.public_send(ScimRails.config.group_reprovision_method, params)
      json_scim_response(object: group)
    end

    def destroy
      group = @company.public_send(ScimRails.config.scim_groups_scope).find(params[:id])
      delete_group(group)
      json_scim_response(object: group)
    end

    private

    def permitted_group_params
      attrs = ScimRails.config.mutable_group_attributes.each.with_object({}) do |attribute, hash|
        hash[attribute] = find_value_for(attribute)
      end

      attrs.merge(ScimRails.config.group_static_attributes)
    end

    def find_value_for(attribute)
      params.dig(*path_for(attribute))
    end

    def path_for(attribute, object = ScimRails.config.mutable_group_attributes_schema, path = [])
      at_path = path.empty? ? object : object.dig(*path)
      return path if at_path == attribute

      case at_path
      when Hash
        at_path.each do |key, value|
          found_path = path_for(attribute, object, [*path, key])
          return found_path if found_path
        end
        nil
      when Array
        at_path.each_with_index do |value, index|
          found_path = path_for(attribute, object, [*path, index])
          return found_path if found_path
        end
        nil
      end
    end

    def delete_group(group)
      accept_args = ScimRails.config.scim_groups_model.instance_method(ScimRails.config.group_delete_method).arity > 0
      args = accept_args ? [@company] : []
      group.public_send(ScimRails.config.group_delete_method, *args)
    end
  end
end
