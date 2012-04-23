require File.join(File.dirname(__FILE__),'api_helper')

describe "RhoconnectApiFastUpdate" do
  it_should_behave_like "ApiHelper"
  
  it "should update an attribute and add new one for an object in rhosync's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_state(@s.docname(:md) => data,@s.docname(:md_size) => '3')
    
    orig_obj_attrs = {'3' => {'price' => @product3['price']}}
    new_obj_attrs = {'3' => {'price' => '0.99', 'new_attr' => 'new_value'}}
    
    post "/api/fast_update", :api_token => @api_token, 
      :user_id => @u.id, :source_id => @s_fields[:name], :delete_data => orig_obj_attrs, :data => new_obj_attrs
    last_response.should be_ok
    data['3'].merge!(new_obj_attrs['3'])
    verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'3')
  end
  
  it "should update one attr, add one attr, and remove one attr for an object in rhosync's :md" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_state(@s.docname(:md) => data,@s.docname(:md_size) => '3')
    
    orig_obj_attrs = {'3' => {'name' => @product3['name'], 'price' => @product3['price']}}
    new_obj_attrs = {'3' => {'price' => '0.99', 'new_attr' => 'new_value'}}
    
    post "/api/fast_update", :api_token => @api_token, 
      :user_id => @u.id, :source_id => @s_fields[:name], :delete_data => orig_obj_attrs, :data => new_obj_attrs
    last_response.should be_ok
    data['3'].delete('name')
    data['3'].merge!(new_obj_attrs['3'])
    verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'3')
  end
  
  it "should remove all attributes , but leave the count incorrect (because fast_update doesn't check if the whole object is deleted)" do
    data = {'1' => @product1, '2' => @product2, '3' => @product3}
    @s = Source.load(@s_fields[:name],@s_params)
    set_state(@s.docname(:md) => data,@s.docname(:md_size) => '3')
    
    orig_obj_attrs = {'3' => @product3}
    new_obj_attrs = {}
    
    post "/api/fast_update", :api_token => @api_token, 
      :user_id => @u.id, :source_id => @s_fields[:name], :delete_data => orig_obj_attrs, :data => new_obj_attrs
    last_response.should be_ok
    data.delete('3')
    verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'3')
  end
end