require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Ping Android" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  before do
    @params = {"device_pin" => @c.device_pin,
      "sources" => [@s.name], "message" => 'hello world', 
      "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
    @response = mock('response')
  end
  
  it "should ping android successfully" do
    result = 'id=0:34234234134254%abc123\n'
    @response.stub!(:code).and_return(200)
    @response.stub!(:body).and_return(result)
    RestClient.stub!(:post).and_return(@response)
    Android.ping(@params).body.should == result
  end
  
  it "should ping android with 503 connection error" do
    error = 'Connection refused'
    @response.stub!(:body).and_return(error)
    RestClient.stub!(:post).and_return { raise RestClient::Exception.new(@response,503) }
    Android.should_receive(:log).twice
    lambda { Android.ping(@params) }.should raise_error(RestClient::Exception)
  end
  
  it "should ping android with 200 error message" do
    error = 'Error=QuotaExceeded'
    @response.stub!(:code).and_return(200)
    @response.stub!(:body).and_return(error)
    @response.stub!(:[]).and_return(nil)
    RestClient.stub!(:post).and_yield(@response)
    Android.should_receive(:log).twice
    lambda { Android.ping(@params) }.should raise_error(Android::AndroidPingError, "Android ping error: QuotaExceeded")
  end
  
  it "should ping android with stale auth token" do
    @response.stub!(:code).and_return(200)
    @response.stub!(:body).and_return('')
    @response.stub!(:[]).and_return({:update_client_auth => 'abc123'})
    RestClient.stub!(:post).and_yield(@response)
    Android.should_receive(:log).twice
    lambda { Android.ping(@params) }.should raise_error(
      Android::StaleAuthToken, "Stale auth token, please update :authtoken: in settings.yml."
    )
  end
  
  it "should compute c2d_message" do
    expected = {'registration_id' => @c.device_pin, 'collapse_key' => "RAND_KEY",
      'data.do_sync' => @s.name,
      'data.alert' => "hello world",
      'data.vibrate' => '5',
      'data.sound' => "hello.mp3"}
    actual = Android.c2d_message(@params)
    actual['collapse_key'] = "RAND_KEY" unless actual['collapse_key'].nil?
    actual.should == expected
  end
  
  it "should trim empty or nil params from c2d_message" do
    expected = {'registration_id' => @c.device_pin, 'collapse_key' => "RAND_KEY",
      'data.vibrate' => '5', 'data.do_sync' => '', 'data.sound' => "hello.mp3"}
    params = {"device_pin" => @c.device_pin,
      "sources" => [], "message" => '', "vibrate" => '5', "sound" => 'hello.mp3'}
    actual = Android.c2d_message(params)
    actual['collapse_key'] = "RAND_KEY" unless actual['collapse_key'].nil?
    actual.should == expected
  end
end
