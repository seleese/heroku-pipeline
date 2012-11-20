require "json"

class Cisaurus

  CLIENT_VERSION = "0.6-ALPHA"
  DEFAULT_HOST = ENV['CISAURUS_HOST'] || "cisaurus.heroku.com"

  def initialize(api_key, host = DEFAULT_HOST, api_version = "v1")
    protocol  = (host.start_with? "localhost") ? "http" : "https"
    @base_url = "#{protocol}://:#{api_key}@#{host}"
    @ver_url  = "#{@base_url}/#{api_version}"
  end

  def downstreams(app, depth=nil)
    JSON.parse RestClient.get pipeline_resource(app, "downstreams"), options(params :depth => depth)
  end

  def addDownstream(app, ds)
    RestClient.post pipeline_resource(app, "downstreams", ds), "", options
  end

  def removeDownstream(app, ds)
    RestClient.delete pipeline_resource(app, "downstreams", ds), options
  end

  def diff(app)
    JSON.parse RestClient.get pipeline_resource(app, "diff"), options
  end

  def promote(app, interval = 2)
    response = RestClient.post pipeline_resource(app, "promote"), "", options
    while response.code == 202
      response = RestClient.get @base_url + response.options[:location], options
      sleep(interval)
      yield
    end
    JSON.parse response
  end

  private

  def pipeline_resource(app, *extras)
    "#{@ver_url}/" + extras.unshift("apps/#{app}/pipeline").join("/")
  end

  def params(tuples = {})
    { :params => tuples.reject { |k,v| k.nil? || v.nil? } }
  end

  def options(extras = {})
    {
        'User-Agent'       => "cli-plugin/#{CLIENT_VERSION}",
        'X-Ruby-Version'   => RUBY_VERSION,
        'X-Ruby-Platform'  => RUBY_PLATFORM
    }.merge(extras)
  end
end