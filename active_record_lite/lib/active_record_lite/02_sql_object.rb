require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'

class MassObject
  def self.parse_all(results)
    items = []

    results.each do |var_hash|
      tmp = self.new(var_hash)
      items << tmp
    end

    items
  end
end

class SQLObject < MassObject

  def self.columns
    column_sql = <<-SQL
    SELECT
    *
    FROM
    #{self.table_name}
    LIMIT
    0;
    SQL

    @columns ||= begin
      cols = DBConnection.instance.execute2(column_sql).first.map(&:to_sym)

      cols.each do |attribute|
        define_method(attribute) do
          self.attributes[attribute]
        end

        define_method("#{attribute}=") do |arg|
          self.attributes[attribute] = arg
        end
      end

      cols
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.underscore.pluralize
  end

  def self.all
    items = DBConnection.instance.execute("SELECT * FROM cats")

    self.parse_all(items)
  end

  def self.find(id)
    find_sql = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id};
    SQL

    found = DBConnection.instance.execute(find_sql)
    self.parse_all(found).first
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    insert_sql = <<-SQL
    INSERT INTO #{self.class.table_name}
      (#{self.class.columns.drop(1).join(', ')})
    VALUES
      (#{gen_q_marks});
    SQL

    DBConnection.instance.execute(insert_sql, self.attribute_values)
    @attributes[:id] = DBConnection.instance.last_insert_row_id
  end

  def initialize(params = {})
    @attributes = {}
    set_attributes(params)
  end

  def save
    self.id.nil? ? self.insert : self.update
  end

  def update
    update_sql = <<-SQL
    UPDATE
      #{self.class.table_name}
    SET
      #{gen_update_sets};
    WHERE
      id = #{self.id}
    SQL

    DBConnection.instance.execute(update_sql, self.attribute_values.drop(1))
  end

  def attribute_values
    @attributes.values
  end

  private
  def gen_q_marks
    marks = ''

    self.attribute_values.length.times do
      marks << "?, "
    end

    marks[0..-3]
  end

  def gen_update_sets
    self.class.columns.drop(1).map do |col|
      "#{col} = ?"
    end.join(', ')
  end

  def set_attributes(params)
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k.to_sym)
      @attributes[k.to_sym] = v
    end
  end
end





