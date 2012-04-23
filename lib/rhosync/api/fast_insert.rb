Server.api :fast_insert do |params,user|
  source = Source.load(params[:source_id],{:app_id=>APP_NAME,:user_id=>params[:user_id]})
  source_sync = SourceSync.new(source)
  timeout = params[:timeout] || 10
  raise_on_expire = params[:raise_on_expire] || false
  source_sync.fast_insert(params[:data], timeout,raise_on_expire)
  'done'
end