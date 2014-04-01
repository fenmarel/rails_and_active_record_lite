require_relative '03_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key,
  )

  def model_class
    @name.to_s.singularize.camelize.constantize
  end

  def table_name
    model_class.table_name
  end

  def update_params(options = {})
    options.each do |k, v|
      self.instance_variable_set("@#{k}", v)
    end
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @class_name = @name.to_s.singularize.camelize
    @primary_key = :id
    @foreign_key = "#{@name}_id".to_sym
    update_params(options)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @class_name = @name.to_s.singularize.camelize
    @primary_key = :id
    @foreign_key = "#{self_class_name.underscore}_id".to_sym
    update_params(options)
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    @association_options = { name => options }

    define_method(name) do
      f_key = self.send(options.foreign_key)
      options.model_class.find(f_key)
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      p_key = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => p_key)
    end
  end

  def assoc_options
    @association_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
