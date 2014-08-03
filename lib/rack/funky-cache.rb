require 'fileutils'
require 'rack'

module Rack

  class FunkyCache
    
    def initialize(app, settings={})
      @app = app       
      @settings   = settings
      @root       = settings[:root] || Dir.pwd
      @path       = settings[:path] || "/public"
      @directory  = settings[:directory] || ::File.join(@root, @path)
      @file_types = settings[:file_types] || [ %r{text/html} ]
    end

    def call(env)
      response = @app.call(env)
      cache(env, response) if should_cache(env, response)
      response
    end

    def cache(env, response)
      path = Rack::Utils.unescape(env["PATH_INFO"])
            
      if path[-1, 1] == "/"
        path = ::File.join(path, "index.html")
      else
        path << '.html'         
      end      
        
      basename  = ::File.basename(path)
      dirname   = ::File.join(@directory, ::File.dirname(path))
      cachefile = ::File.join(dirname, basename)

      FileUtils.mkdir_p(dirname) unless ::File.directory?(dirname)
      unless ::File.exists?(cachefile)
        ::File.open(cachefile, "w") do |file|
          response[2].each do |string| 
            file.write(string)
          end
        end
      end
      
    end
    
    def should_cache(env, response)
      unless env_excluded?(env)
        request = Rack::Request.new(env)
        content_type = response[1]["Content-Type"]
        request.get? && request.query_string.empty? &&
          @file_types.detect { |t| t =~ content_type } && 200 == response[0]
      end
    end

    def env_excluded?(env)
      @settings[:exclude] && @settings[:exclude].call(env)
    end
        
  end
end
