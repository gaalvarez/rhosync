require 'json'
require 'rest_client'

class Product < SourceAdapter
  def initialize(source,credential)
    @base = 'http://rhostore.heroku.com/products'
    super(source,credential)
  end
 
  def login
    # TODO: Login to your data source here if necessary
  end
 
  def query(params=nil)
    # parsed=JSON.parse(RestClient.get("#{@base}.json").body)
    log "inside query #{@base/query}"
     #res = RestClient.get("#{@base}/query")
     parsed=JSON.parse(RestClient.get("#{@base/query}.json").body)

       @result={}
       if parsed
         parsed.each do |item| 
           key = item["product"]["id"].to_s
           @result[key]=item["product"]
         end
       end
    #raise SourceAdapterException.new("Please provide some code to read records from the backend data source")
  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
      # TODO: Create a new record in your backend data source
      # If your rhodes rhom object contains image/binary data 
      # (has the image_uri attribute), then a blob will be provided
      #raise "Please provide some code to create a single record in the backend data source using the create_hash"
      result = RestClient.post(@base + '/create',:product => create_hash)
      
      # after create we are redirected to the new record.
      # The URL of the new record is given in the location header
      location = "#{result.headers[:location]}.json"

      # We need to get the id of that record and return it as part of create
      # so rhosync can establish a link from its temporary object on the
      # client to this newly created object on the server

      new_record = RestClient.get(location).body
      JSON.parse(new_record)["product"]["id"].to_s
  end
 
  def update(update_hash)
    # TODO: Update an existing record in your backend data source
    raise "Please provide some code to update a single record in the backend data source using the update_hash"
  end
 
  def delete(delete_hash)
    # TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the object_id"
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end
end