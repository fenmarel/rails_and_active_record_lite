require_relative 'db_connection'
require_relative '02_sql_object'

module Searchable
  def where(params)
    where_sql = <<-SQL
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{gen_where_sql(params.keys)}
    SQL

    results = DBConnection.instance.execute(where_sql, params.values)
    self.parse_all(results)
  end

  def gen_where_sql(param_names)
    where_sql = []

    param_names.each do |name|
      where_sql << "#{name} = ?"
    end

    where_sql.join(' AND ')
  end
end

class SQLObject
  extend Searchable
end
