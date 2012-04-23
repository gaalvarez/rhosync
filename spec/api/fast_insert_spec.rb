require File.join(File.dirname(__FILE__),'api_helper')

describe "RhoconnectApiFastInsert" do
  it_should_behave_like "ApiHelper" do
    it "should append new objects to rhosync's :md" do
      data = {'1' => @product1, '2' => @product2}
      @s = Source.load(@s_fields[:name],@s_params)
      set_state(@s.docname(:md) => data,@s.docname(:md_size) => '2')
      post "/api/fast_insert", :api_token => @api_token, 
        :user_id => @u.id, :source_id => @s_fields[:name], :data => {'3' => @product3}
      last_response.should be_ok
      data.merge!({'3' => @product3})
      verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'3')
    end

    it "should incorrectly append data to existing object (because fast_insert doesn't ensure any data integrity)" do
      data = {'1' => @product1, '2' => @product2, '3' => @product3}
      incorrect_insert = {'3' => {'price' => '1.99', 'new_field' => 'value'}}
      @s = Source.load(@s_fields[:name],@s_params)
      set_state(@s.docname(:md) => data,@s.docname(:md_size) => '3')
      post "/api/fast_insert", :api_token => @api_token, 
        :user_id => @u.id, :source_id => @s_fields[:name], :data => incorrect_insert
      last_response.should be_ok
      data['3'].merge!(incorrect_insert['3'])
      verify_result(@s.docname(:md) => data,@s.docname(:md_size)=>'4')
    end
  end  
end