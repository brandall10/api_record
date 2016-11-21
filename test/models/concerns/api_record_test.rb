require 'test_helper'

class ApiRecordTest < ActiveSupport::TestCase
  setup do
    Temping.create :ApiRecordTester do
      with_columns do |t|
        t.string :string_field
        t.integer :numeric_field
        t.boolean :boolean_field
      end

      include ApiRecord 

      has_api_attr_mappings :a_string  => :string_field,
                            :falsey => :boolean_field,
                            :integer_like => :numeric_field,
                            :blah => :nil
    end
  end

  teardown do
    Temping.teardown
  end

  test "it should initialize from _api_source" do
    api_object = { 
      string_field: 'This is a string',
      boolean_field: false,
      numeric_field: 55 
    }

    res = ApiRecordTester.new(_api_object: api_object)

    assert_equal 'This is a string', res.string_field
    assert_equal false, res.boolean_field
    assert_equal 55, res.numeric_field
    assert_empty res.invalid_api_attrs
  end

  test "it should remap fields" do
    api_object = { 
      a_string: 'This is a string',
      falsey: false,
      integer_like: 55 
    }

    res = ApiRecordTester.new(_api_object: api_object)

    assert_equal 'This is a string', res.string_field
    assert_equal false, res.boolean_field
    assert_equal 55, res.numeric_field
    assert_empty res.invalid_api_attrs
  end

  test "it should track invalid attributes" do
    api_object = { 
      not_a_string: 'This is a string',
      not_a_falsey: false,
      not_an_integer_like: 55 
    }

    res = ApiRecordTester.new(_api_object: api_object)

    assert_nil res.string_field
    assert_nil res.boolean_field
    assert_nil res.numeric_field
    assert_equal [:not_a_string, :not_a_falsey, :not_an_integer_like], res.invalid_api_attrs
  end

  test "it should not permit invalid attributes by default" do
    api_object = { 
      not_a_string: 'This is a string',
      not_a_falsey: false,
      not_an_integer_like: 55 
    }

    res = ApiRecordTester.new(_api_object: api_object)

    assert_not res.valid?
  end

  test "it should permit invalid attributes if specified" do
    api_object = { 
      not_a_string: 'This is a string',
      not_a_falsey: false,
      not_an_integer_like: 55 
    }

    res = ApiRecordTester.new(_api_object: api_object)

    ApiRecordTester.permit_invalid_api_attrs

    assert res.valid?
  end

  test "it should strip fields mapped to :nil" do
    res = ApiRecordTester.new(_api_object: {blah: 'Strip this out'})

    assert res.valid?
    assert_empty res.invalid_api_attrs
  end
end
