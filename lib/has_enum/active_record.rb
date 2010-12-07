module HasEnum
  module ActiveRecord
    def self.included(base)
      base.write_inheritable_hash(:enum, {})
      base.extend(ClassMethods)
    end

    module ClassMethods
      def enum(attribute = nil)
        @enum ||= read_inheritable_attribute(:enum)
        attribute ? @enum[attribute.to_sym] : @enum
      end

      
      def has_enum(attributes, values, options = {})
        [*attributes].each do |attribute|
          attribute = attribute.to_sym
          if options[:symbols]
            values = values.map{|value| value.to_s.insert(0, ':')}
          else
            values = values.map(&:to_s)
          end
          enum[attribute] = values.freeze
          
          if options[:query_methods] != false
            enum[attribute].each do |val|
              if options[:symbols]
                define_method(:"#{val[1..-1]}?") do
                  self.send(attribute).to_s == val[1..-1]
                end
              else
                define_method(:"#{val}?") do
                  self.send(attribute) == val
                end
              end
            end
          end
          
          define_method(:"#{attribute}=") do |value|
            value = value.to_s.insert(0, ':') if options[:symbols]

            if values.find{ |val| val == value }
              write_attribute(attribute, value.blank? ? nil : value.to_s)
            else
              errors.add(:"#{attribute}", "#{value} is not in enum")
            end
          end
          
          define_method(:"#{attribute}") do
            if options[:symbols]
              read_attribute(attribute.to_sym).tap{|str| str.slice!(0)}.to_sym
            else
              read_attribute(attribute.to_sym)
            end
          end
          
          define_method "human_#{attribute}" do
            begin
              key = "activerecord.attributes.#{self.class.name.underscore}.#{attribute}_enum.#{self.send(attribute)}"
              translation = I18n.translate(key, :raise => true)
            rescue I18n::MissingTranslationData
              self.send(attribute).humanize
            end
          end

        end
      end

      def values_for_select_tag(enum)
        values = enum(enum)
        begin
          translation = I18n.translate("activerecord.attributes.#{self.name.underscore}.#{enum}_enum", :raise => true)
          values.map { |value| [translation[value.to_sym], value] }
        rescue I18n::MissingTranslationData
          values.map { |value| [value.humanize, value] }
        end
      end
    end
  end
end