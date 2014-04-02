require 'uri'
require 'json'

class Params
  def initialize(req, route_params = {})
    @query = req.query_string
    @body = req.body
    @params = parse_www_encoded_form(@query)
              .merge(parse_www_encoded_form(@body))
              .merge(route_params)
    @permitted = []
  end

  def [](key)
    @params[key]
  end

  def permit(*keys)
    keys.each do |key|
      @permitted << key
    end
  end

  def require(key)
    required = @params[key]

    required.nil? ? raise(AttributeNotFoundError) : required
  end

  def permitted?(key)
    @permitted.include?(key)
  end

  def to_s
    @params.to_json
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    return {} if www_encoded_form.nil?

    raw_params = URI.decode_www_form(www_encoded_form)

    raw_params.map! do |param_set|
      parse_key(param_set)
    end

    build_params(raw_params)
  end

  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.map do |param|
      param.gsub(']', '').split('[')
    end.flatten
  end

  def build_params(raw)
    @params = {}

    raw.each do |param_set|
      tmp = param_set.dup
      last_val = tmp.pop
      current_path = "@params"

      tmp.each_with_index do |key, i|
        current_path << "['#{key}']"
        eval("#{current_path} ||= {}")

        if i == tmp.length - 1
          eval("#{current_path}='#{last_val}'")
        end
      end
    end

    @params
  end
end
