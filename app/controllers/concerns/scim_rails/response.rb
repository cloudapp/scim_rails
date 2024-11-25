module ScimRails
  module Response
    CONTENT_TYPE = "application/scim+json".freeze

    def json_response(object, status = :ok)
      render \
        json: object,
        status: status,
        content_type: CONTENT_TYPE
    end

    def json_scim_response(object:, status: :ok, counts: nil)
      case params[:action]
      when "index"
        render \
          json: list_response(object, counts),
          status: status,
          content_type: CONTENT_TYPE
      when "show", "create", "put_update", "patch_update"
        render \
          json: resource_response(object),
          status: status,
          content_type: CONTENT_TYPE
      end
    end

    private

    def list_response(object, counts)
      resources = paginate(object, counts)
      {
        "schemas": [
            "urn:ietf:params:scim:api:messages:2.0:ListResponse"
        ],
        "totalResults": counts.total,
        "startIndex": counts.start_index,
        "itemsPerPage": counts.limit,
        "Resources": list_resources(resources)
      }
    end

    def paginate(object, counts)
      object.order(:id).offset(counts.offset).limit(counts.limit)
    end

    def list_resources(resources)
      resources.map { |resource| resource_response(resource) }
    end

    def resource_response(resource)
      schema = schema_for(resource)
      find_value(resource, schema)
    end

    def schema_for(resource)
      if resource.is_a?(User)
        ScimRails.config.user_schema
      elsif resource.is_a?(Group)
        if params[:action] == "index"
          ScimRails.config.group_list_schema
        else
          ScimRails.config.group_schema
        end
      else
        raise "Unsupported resource type: #{resource.class.name}"
      end
    end

    # `find_value` is a recursive method that takes a "user" and a
    # "user schema" and replaces any symbols in the schema with the
    # corresponding value from the user. Given a schema with symbols,
    # `find_value` will search through the object for the symbols,
    # send those symbols to the model, and replace the symbol with
    # the return value.
    def find_value(resource, schema)
      case schema
      when Hash
        schema.each.with_object({}) do |(key, value), hash|
          hash[key] = find_value(resource, value)
        end
      when Array
        schema.map { |value| find_value(resource, value) }
      when Symbol
        resource.public_send(schema)
      else
        schema
      end
    end
  end
end
