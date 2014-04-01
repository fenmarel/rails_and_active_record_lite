require_relative '04_associatable'

# Phase V
module Associatable

  def has_one_through(name, through_name, source_name)
    through_options = @association_options[through_name]

    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]

      p_key = self.send(source_options.primary_key)

      source_table = source_options.table_name
      through_table = through_options.table_name

      source_table_f_id = source_options.foreign_key
      source_table_p_id = source_options.primary_key

      through_table_p_id = through_options.primary_key

      query = <<-SQL
        SELECT
          #{source_table}.*
        FROM
          #{source_table} JOIN #{through_table}
            ON #{source_table}.#{source_table_p_id} = #{through_table}.#{source_table_f_id}
        WHERE
          #{through_table}.#{through_table_p_id} = ?;
      SQL

      results = DBConnection.instance.execute(query, p_key)
      source_options.model_class.parse_all(results).first
    end
  end
end
