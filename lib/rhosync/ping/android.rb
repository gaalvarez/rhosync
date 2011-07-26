require 'rest_client'
require 'uri'

module Rhosync
  class Android
    class StaleAuthToken < Exception; end
    class InvalidAuthToken < Exception; end
    class AndroidPingError < Exception; end
    
    def self.ping(params)
      begin
        settings = get_config(Rhosync.base_directory)[Rhosync.environment]
        authtoken = settings[:authtoken]
              
        RestClient.post(
          'https://android.apis.google.com/c2dm/send', c2d_message(params), 
          :authorization => "GoogleLogin auth=#{authtoken}"
        ) do |response, request, result, &block|
          # return exceptions based on response code & body
          case response.code
          when 200
            # TODO: Automate authtoken updates
            if response[:update_client_auth]
              raise StaleAuthToken.new(
                "Stale auth token, please update :authtoken: in settings.yml."
              )
            # body will contain the exception class
            elsif response.body =~ /^Error=(.*)$/
              raise AndroidPingError.new("Android ping error: #{$1 || ''}")
            end
          when 401, 403
            raise InvalidAuthToken.new("Invalid auth token, please update :authtoken: in settings.yml.")
          else
            response.return!(request, result, &block)
          end
        end
      rescue Exception => error
        log error
        log error.backtrace.join("\n")
        raise error
      end
    end
    
    def self.c2d_message(params)
      params.reject! {|k,v| v.nil? || v.length == 0}
      data = {}
      data['registration_id'] = params['device_pin']
      data['collapse_key'] = (rand * 100000000).to_i.to_s
      data['data.do_sync'] = params['sources'] ? params['sources'].join(',') : ''
      data['data.alert'] = params['message'] if params['message']
      data['data.vibrate'] = params['vibrate'] if params['vibrate']
      data['data.sound'] = params['sound'] if params['sound']
      data['data.phone_id'] = params['phone_id'] if params['phone_id']
      data
    end
  end
end
