$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'sinatra/base'
require 'erb'
require 'json'
require 'rhosync_api'

module RhosyncConsole  
  class << self
    ROOT_DIR = File.dirname(File.expand_path(__FILE__)) unless defined? ROOT_DIR

    def root_path(*args)
      File.join(ROOT_DIR, *args)
    end
  end  

  class Server < Sinatra::Base
    set :views,           RhosyncConsole::root_path("app","views")
    if Sinatra.const_defined?("VERSION") && Gem::Version.new(Sinatra::VERSION) >= Gem::Version.new("1.3.0")
      set :public_folder, RhosyncConsole::root_path("app","public")
    else
     	set :public,        RhosyncConsole::root_path("app","public")
    end
    set :static,          true
    use Rack::Session::Cookie
    before do
      headers['Expires'] = 'Sun, 19 Nov 1978 05:00:00 GMT'
      headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'  
      headers['Pramga'] = 'no-cache'
    end
    
  end
end

Dir[File.join(File.dirname(__FILE__),"app/**/*.rb")].each do |file|
  require file
end