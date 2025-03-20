# frozen_string_literal: true

require "test_helper"

module ActionMCP
  class ResourceTemplatesRegistryTest < ActiveSupport::TestCase
    def setup
      # Save original registered templates
      @original_templates = ResourceTemplate.registered_templates.dup
      # Clear for testing
      ResourceTemplate.instance_variable_set(:@registered_templates, [])

      # Create some test templates
      @user_profile_template = Class.new(ResourceTemplate) do
        def self.name = "UserProfileTemplate"
        uri_template "service://users/{id}/profile"
        description "User profile"
      end

      @user_template = Class.new(ResourceTemplate) do
        def self.name = "UserTemplate"
        uri_template "service://users/{id}"
        description "User resource"
      end

      @product_template = Class.new(ResourceTemplate) do
        def self.name = "ProductTemplate"
        uri_template "service://products/{id}"
        description "Product resource"
      end

      @category_products_template = Class.new(ResourceTemplate) do
        def self.name = "CategoryProductsTemplate"
        uri_template "service://categories/{category_id}/products"
        description "Products in a category"
      end
    end

    def teardown
      # Restore original registered templates
      ResourceTemplate.instance_variable_set(:@registered_templates, @original_templates)
    end

    test "finds the correct template for a URI" do
      uri = "service://users/123/profile"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      assert_equal @user_profile_template, template

      uri = "service://users/456"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      assert_equal @user_template, template

      uri = "service://products/789"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      assert_equal @product_template, template
    end

    test "returns nil for URIs that don't match any template" do
      uri = "service://unknown/resource"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      assert_nil template

      uri = "different://users/123"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      assert_nil template
    end

    test "selects the most specific template when multiple match" do
      # Add a more specific template
      specific_template = Class.new(ResourceTemplate) do
        def self.name = "SpecificUserTemplate"
        uri_template "service://users/admin/profile"
        description "Admin user profile"
      end

      # This should match the specific template
      uri = "service://users/admin/profile"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      assert_equal specific_template, template

      # This should still match the generic user profile template
      uri = "service://users/123/profile"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      assert_equal @user_profile_template, template
    end

    test "extracts parameters from a URI" do
      uri = "service://users/123/profile"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      params = ResourceTemplatesRegistry.extract_parameters(uri, template)

      assert_equal({ id: "123" }, params)

      uri = "service://categories/electronics/products"
      template = ResourceTemplatesRegistry.find_template_for_uri(uri)
      params = ResourceTemplatesRegistry.extract_parameters(uri, template)

      assert_equal({ category_id: "electronics" }, params)
    end

    test "returns empty hash for non-matching URIs and templates" do
      uri = "service://users/123"
      template = @product_template
      params = ResourceTemplatesRegistry.extract_parameters(uri, template)
      assert_empty params
    end
  end
end
