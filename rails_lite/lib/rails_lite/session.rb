require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @req = req
    @cookie = parse_session_cookie
  end

  def [](key)
    @cookie[key]
  end

  def []=(key, val)
    @cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app', @cookie.to_json)
  end

  private

  def parse_session_cookie
    @req.cookies.each do |cookie|
      if cookie.name == '_rails_lite_app'
        return JSON.parse(cookie.value)
      end
    end
    {}
  end
end
