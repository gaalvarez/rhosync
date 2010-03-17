#gem 'sevenwire-rest-client'
require 'rest_client'
require 'log4r'
require 'json'
require 'mechanize'
require 'zip/zip'
$:.unshift File.dirname(__FILE__)
require 'trunner/timer'
require 'trunner/logging'
require 'trunner/utils'
require 'trunner/result'
require 'trunner/session'
require 'trunner/runner'
require 'trunner/statistics'
require 'trunner/cli'
require 'trunner/test_data'
$:.unshift File.join(File.dirname(__FILE__),'..')
require 'scripts/helpers'

# Inspired by Trample: http://github.com/jamesgolick/trample

module Trunner
  class << self
    include Logging
    include TestData
    include Utils

    attr_accessor :concurrency, :iterations, :admin_login 
    attr_accessor :admin_password, :user_name, :app_name
    attr_accessor :password, :host, :base_url, :token
    attr_accessor :total_time, :sessions, :verify_error
    
    def config
      begin
        @verify_error ||= false
        yield self
      rescue Exception => e
        puts "error in config: #{e.inspect}"
        raise e
      end
    end
    
    def get_server_state(doc)
      token = get_token
      @body = RestClient.post("#{@host}/api/get_db_doc",
        {:api_token => token, :doc => doc}.to_json, :content_type => :json)
      JSON.parse(@body.to_s)
    end
    
    def import_app
      token = get_token
      file = File.join(File.dirname(__FILE__),'..',@app_name,'rhosync')
      zipfile = compress(file)
      Mechanize.new.post("#{@host}/api/import_app",
        :app_name => @app_name, :api_token => token,
        :upload_file =>  File.new(zipfile, "rb"))
      FileUtils.rm zipfile, :force => true
    end
    
    def create_user
      token = get_token
      RestClient.post("#{@host}/api/create_user",
        {:api_token => token, :app_name => @app_name,
         :attributes => {:login => @user_name, :password => @password}}.to_json, 
         :content_type => :json)
    end
    
    def set_server_state(doc,data)
      token = get_token
      RestClient.post("#{@host}/api/set_db_doc",
        {:api_token => token, :doc => doc, :data => data}.to_json, :content_type => :json)
    end
    
    def reset_refresh_time(source_name,poll_interval=nil)
      token = get_token
      RestClient.post("#{@host}/api/set_refresh_time",
        {:api_token => token, :source_name => source_name,
          :app_name => @app_name, :user_name => @user_name, 
          :poll_interval => poll_interval}.to_json, 
          :content_type => :json)
    end
    
    def get_token
      unless @token
        res = RestClient.post("#{@host}/login", 
          {:login => @admin_login, :password => @admin_password}.to_json, :content_type => :json)
        @token = RestClient.post("#{@host}/api/get_api_token",'',{:cookies => res.cookies})
      end
      @token
    end
    
    def get_test_server
      process_rhoconfig(File.join(File.dirname(__FILE__),'..',@app_name,'rhoconfig.txt'))
      @base_url = $rhoconfig['syncserver'].gsub(/\/$/,'')
      uri = URI.parse(@base_url)
      port = (uri.port and uri.port != 80) ? ":"+uri.port.to_s : "" 
      @host = "#{uri.scheme}://#{uri.host}#{port}"
      puts "Test server is #{@host}..."
    end
  
    def test(&block)
      Runner.new.test(@concurrency,@iterations,&block)
    end
    
    def verify(&block)
      yield self,@sessions
    end
    
    # TODO: These functions are duplicates!
    
    def compress(path)
      path.sub!(%r[/$],'')
      archive = File.join(path,File.basename(path))+'.zip'
      FileUtils.rm archive, :force=>true
      Zip::ZipFile.open(archive, 'w') do |zipfile|
        Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
          zipfile.add(file.sub(path+'/',''),file)
        end
      end
      archive
    end
    
    # TODO: Share this code with the framework Rho class
    def process_rhoconfig(file)
      begin
        $rhoconfig = {}
        File.open(file).each do |line|
          # Skip empty or commented out lines
          next if line =~ /^\s*(#|$)/
          parts = line.chomp.split('=')
          key = parts[0]
          value = parts[1] if parts[1]
          if key and value
            val = value.strip.gsub(/\'|\"/,'')
            val = val == 'nil' ? nil : val
            $rhoconfig[key.strip] = val
          end  
        end
      rescue Exception => e
        puts "Error opening rhoconfig.txt: #{e}, using defaults."
        puts e.backtrace.join("\n")
      end
    end
  end
end