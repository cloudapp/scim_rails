# frozen_string_literal: true

module ScimRails
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end
  end

  # Class containing configuration of ScimRails
  class Config
    ALGO_NONE = "none"

    attr_writer \
      :basic_auth_model,
      :mutable_user_attributes_schema,
      :scim_users_model,
      :mutable_group_attributes_schema,
      :scim_groups_model

    attr_accessor \
      :basic_auth_model_authenticatable_attribute,
      :basic_auth_model_searchable_attribute,
      :mutable_user_attributes,
      :on_error,
      :queryable_user_attributes,
      :scim_users_list_order,
      :scim_users_scope,
      :scim_user_prevent_update_on_create,
      :scim_user_create_guard,
      :signing_secret,
      :signing_algorithm,
      :user_attributes,
      :user_static_attributes,
      :user_deprovision_method,
      :user_reprovision_method,
      :user_delete_method,
      :user_schema,
      :mutable_group_attributes,
      :group_static_attributes,
      :scim_groups_scope,
      :group_schema,
      :group_list_schema,
      :queryable_group_attributes,
      :scim_group_prevent_update_on_create,
      :group_reprovision_method,
      :group_deprovision_method,
      :group_create_method,
      :scim_groups_list_order,
      :scim_group_create_guard,
      :group_delete_method

    def initialize
      @basic_auth_model = "Company"
      @scim_users_list_order = :id
      @scim_users_model = "User"
      @signing_algorithm = ALGO_NONE
      @user_schema = {}
      @user_attributes = []
      @user_static_attributes = {}
      @scim_user_create_guard = nil
      @scim_groups_model = "Group"
      @mutable_group_attributes = []
      @group_schema = {}
      @queryable_group_attributes = {}
      @group_static_attributes = {}
      @mutable_group_attributes_schema = {}
    end

    def mutable_user_attributes_schema
      @mutable_user_attributes_schema || @user_schema
    end

    def mutable_group_attributes_schema
      @mutable_group_attributes_schema || @group_schema
    end

    def basic_auth_model
      @basic_auth_model.constantize
    end

    def scim_users_model
      @scim_users_model.constantize
    end

    def scim_groups_model
      @scim_groups_model.constantize
    end
  end
end
