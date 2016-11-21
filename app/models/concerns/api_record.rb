require 'active_support/concern'

module ApiRecord
  extend ActiveSupport::Concern

  included do
    class_attribute :allows_invalid_api_attrs
    self.allows_invalid_api_attrs = false

    attr_accessor :invalid_api_attrs
    validates :invalid_api_attrs, absence: { message: "%{value}" }, unless: "allows_invalid_api_attrs?"
  end

  # Define features at the class level
  class_methods do
    def has_api_attr_mappings(api_attr_mappings={})
      class_attribute :api_attr_mappings
      self.api_attr_mappings = api_attr_mappings
    end
    
    def permit_invalid_api_attrs
      self.allows_invalid_api_attrs = true
    end 
  end

  def initialize(attributes=nil)
    # Only apply ApiRecord features if an _api_object is passed in
    if api_attrs = attributes.try(:[], :_api_object)
      # By default merge in all attribs and delete source object
      attributes.merge!(api_attrs).delete(:_api_object)

      # Normalize keys to all symbols
      attributes.symbolize_keys!
      
      # Remap any attributes if defined
      if respond_to? :api_attr_mappings
        attributes = remap_api_attrs attributes
      end
      
      # Permit and log invalid attributes if allowed
      strip_invalid_api_attrs! attributes
    end
   
    # Now all work is done, invoke parent
    super
  end

  private
  def strip_invalid_api_attrs!(attributes)
    self.invalid_api_attrs = []
    columns = self.class.column_names.map(&:to_sym)
    
    attributes.select! { |a| columns.include?(a) ? true : self.invalid_api_attrs << a && false }
  end
  
  def remap_api_attrs(attributes)
    attributes.map{ |k, v| [api_attr_mappings[k]||k, v] }.to_h.reject{|k| k == :nil}
  end
end

