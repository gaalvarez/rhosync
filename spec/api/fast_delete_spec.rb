require File.join(File.dirname(__FILE__),'api_helper')

describe "RhoconnectApiFastDelete" do
  it_should_behave_like "ApiHelper"
  
  it "should delete an object from rhosync's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_state(@s.docname(:md) => data,@s.docname(:md_size) => '3')
    post "/api/fast_delete", :api_token => @api_token, 
      :user_id => @u.id, :source_id => @s_fields[:name], :data => {'3' => @product3}
    last_response.should be_ok
    data.delete('3')
    verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'2')
  end

  it "should not properly delete the object if fast_delete is called without all the attributes (because fast_delete doesn't ensure any data integrity)" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    delete_data = {'3' => {'price' => '1.99'}}
    @s = Source.load(@s_fields[:name],@s_params)
    set_state(@s.docname(:md) => data,@s.docname(:md_size) => '3')
    post "/api/fast_delete", :api_token => @api_token, 
      :user_id => @u.id, :source_id => @s_fields[:name], :data => delete_data
    last_response.should be_ok
    verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'2')
  end
end