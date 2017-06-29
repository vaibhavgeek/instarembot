require 'uri'
require 'net/http'
require 'htmlentities'
  
class BotController < ApplicationController
  


  def index
  	@message = Message.new
  	@messages = Message.where(:session_id => session[:session_id] ).order(created_at: :asc)
    
  end

  def show
  end

  def login
  email =  request.params[:lg_username]
  password = request.params[:lg_password] 
  url = URI("http://stagingapi.instarem.com/v1/api/v1/Login")
  coder = HTMLEntities.new
  body_code = "EmailId=" + coder.encode(email) + "&Password=" + coder.encode(password)
  http = Net::HTTP.new(url.host, url.port)
  
  request = Net::HTTP::Post.new(url)
  request["authorization"] = 'amx 0O1QCg+UcMLTHdfxHJllzWiUfWTw520EMifGt72vTDmRgMXZKJsx001K2Svelvuh'
  request["content-type"] = 'application/x-www-form-urlencoded'
  request["cache-control"] = 'no-cache'
  request["postman-token"] = '79df4610-6ca9-70bc-01fb-3e7264b2d8f6'
  request.body = body_code
  
  response = http.request(request)
  parsed = JSON.parse(response.read_body) 
  puts session[:session_id]
  @status_m =  parsed["statusMessage"]
  @status_code = parsed["statusCode"]
  auth_token = parsed["authToken"]
   respond_to do |format|    
    if @status_code == 200 
      Session.where(:session_id => session[:session_id]).first_or_create.update(:auth_token => auth_token)  
    end
    format.js
   end
  end
  
  def previous
  url = URI("http://stagingapi.instarem.com/v1/api/v1/GetPaymentHistory?fromDate=&toDate=")
  auth_token = Session.where(:session_id => session[:session_id]).first.auth_token
  puts auth_token
http = Net::HTTP.new(url.host, url.port)

request = Net::HTTP::Get.new(url)
request["authorization"] = 'amx ' + auth_token.to_s
request["content-type"] = 'application/x-www-form-urlencoded'
request["cache-control"] = 'no-cache'
request["postman-token"] = 'ab84c662-a0cd-c30d-4b66-7114044bfb1f'

response = http.request(request)
parsed = JSON.parse(response.read_body) 
@prev_transact_1 = parsed["responseData"][0] 
@prev_transact_2 = parsed["responseData"][1]
    respond_to do |format|
      format.js
    end
  end

  def fx_back

    
  end


  def fx
    auth_token = Session.where(:session_id => session[:session_id]).first.auth_token

    url = URI("http://api.instarem.com/api/v1/FxRate?from=USD&to=INR&timeOffset=330")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url)
    request["authorization"] = 'amx ' + auth_token.to_s
    request["content-type"] = 'application/x-www-form-urlencoded'
    request["cache-control"] = 'no-cache'
    request["postman-token"] = 'e62185c3-7a79-b556-1a43-5d4c7715e767'

    response = http.request(request)
    @parsed =  JSON.parse(response.read_body)
  end
  def beneficiary
    auth_token = Session.where(:session_id => session[:session_id]).first.auth_token

    url = URI("http://stagingapi.instarem.com/v1/api/v1/GetPayeeList")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url)
    request["authorization"] = 'amx ' + auth_token.to_s
    request["content-type"] = 'application/x-www-form-urlencoded'
    request["cache-control"] = 'no-cache'
    request["postman-token"] = 'e62185c3-7a79-b556-1a43-5d4c7715e767'

    response = http.request(request)
    @parsed =  JSON.parse(response.read_body)["responseData"]
  end

  def start
     @messages = Message.where(:session_id => session[:session_id] )
     @messages.destroy_all

  end

  def create
  end

  def new
    @messages = Message.where(:session_id => session[:session_id]).order(created_at: :asc)
    
    client = ApiAiRuby::Client.new(
    :client_access_token => '31f5d2bb49ce4577bb5303f72be6ff75'
    )
  	@message = Message.new(message_params)
    response = client.text_request @message.message.to_s
    speech_res = response[:result][:fulfillment][:messages][0][:speech]
  	if session[:session_id]
  		@message.session_id = session[:session_id]
  	else
  		o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
		string = (0...50).map { o[rand(o.length)] }.join
  		@message.session_id = string
  		session[:session_id] = string
  	end
  	respond_to do |format|		
      if @message.save
        Message.create(:message => speech_res , :session_id => session[:session_id] , :from_id => "bot")
        format.js 
      else
      	flash[:notice] = "Error Occured"
      end
    end
  end
  
  private

  def message_params
  	params.require(:message).permit(:message, :session_id , :from_id)
  end 
end
