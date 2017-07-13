require 'uri'
require 'net/http'
require 'htmlentities'
  
class BotController < ApplicationController

helper_method :check_login
  def index
  	@message = Message.new
  	@messages = Message.where(:session_id => session[:session_id] ).order(created_at: :asc)
    
  end

  def show
  end

  def logout
    Session.where(:session_id => session[:session_id]).destroy_all
    session[:session_id] = nil
  end
  def existing
    url_send = "http://stagingapi.instarem.com/v1/api/v1/GetPaymentHistory?fromDate=&toDate="
    puts session[:session_id]
    session_t = Session.where(:session_id => session[:session_id]).count
    if session_t !=0 
       auth_token = Session.where(:session_id => session[:session_id]).first(1).pluck(:auth_token)[0]
       puts auth_token
       response = instarem_api(url_send , nil , auth_token)
       puts response.read_body
       parsed = JSON.parse(response.read_body) 
       if parsed["responseData"] != nil
         @login_allow = "true"
       end
    else
          @login_allow = "false"
    end
  end

  def login
    email =  request.params[:lg_username]
    password = request.params[:lg_password]     
    coder = HTMLEntities.new
    body_code = "EmailId=" + coder.encode(email) + "&Password=" + coder.encode(password)
    response =  login_instarem("http://stagingapi.instarem.com/v1/api/v1/Login" , body_code)
    puts response.read_body
    parsed = JSON.parse(response.read_body) 
    @status_m =  parsed["statusMessage"]
    @status_code = parsed["statusCode"]
    auth_token = parsed["authToken"]
    respond_to do |format|    
      puts @status_code
      if @status_code == 200 
        Session.where(:session_id => session[:session_id]).first_or_create.update(:auth_token => auth_token)  
      end
      format.js
    end
  end
  
  def previous
    uri_send = "http://stagingapi.instarem.com/v1/api/v1/GetPaymentHistory?fromDate=&toDate="
    auth_token = Session.where(:session_id => session[:session_id]).first.auth_token
    puts auth_token
    response = instarem_api(uri_send ,nil ,auth_token)
    parsed = JSON.parse(response.read_body) 
    puts parsed
    @transacts = parsed["responseData"].first(1)
      respond_to do |format|
        format.js
      end
  end

  def fx_back

    
  end

  def get_transaction_status
    respond_to do |format|
      format.js 
    end
  end

  def submit_transaction
    trans_id = "IN" + request.params["ref1"] + request.params["ref2"] + request.params["ref3"] + request.params["ref4"] + request.params["ref5"] + request.params["ref6"]
    url_send = "http://stagingapi.instarem.com/v1/api/v1/GetPaymentDetails?RefNumber="+trans_id
    auth_token = check_login
    response = instarem_api(url_send , nil , auth_token)
    trans_response = JSON.parse(response.read_body)
    puts trans_response
    @trans = trans_response["responseData"]
  end 
  def fx
    #auth_token = Session.where(:session_id => session[:session_id]).first.auth_token
    from = request.params["from_curr"]
    to = request.params["country"]
    puts from 
    puts to
    url_send  = "http://api.instarem.com/api/v1/FxRate?from="+ from +"&to="+to+"&timeOffset=330"
    response = instarem_api(url_send , nil )
    @parsed =  JSON.parse(response.read_body)
  end
  def beneficiary
    auth_token = Session.where(:session_id => session[:session_id]).first.auth_token
    url_send = "http://stagingapi.instarem.com/v1/api/v1/GetPayeeList"
    response = instarem_api(url_send , nil , auth_token)
    @parsed =  JSON.parse(response.read_body)["responseData"].first(3)
  end

  def search_bene
    search_q = request.params["search_tag"].downcase
    auth_token = Session.where(:session_id => session[:session_id]).first.auth_token
    url_send = "http://stagingapi.instarem.com/v1/api/v1/GetPayeeList"
    response = instarem_api(url_send , nil , auth_token)
    @parsed =  JSON.parse(response.read_body)["responseData"].map { |a| a if a["firstName"].to_s.downcase.include? search_q  }.compact
    puts @parsed
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
    puts message_params
    @message = Message.new(message_params)
  	message_text = request.params["message"]["message"]
    @message.message = message_text
    response = client.text_request message_text
    puts response
    if response[:result][:fulfillment][:messages][0][:payload]
      if response[:result][:fulfillment][:messages][0][:payload][:partial] == "showlogin"
        @render_partial = "login"
      elsif response[:result][:fulfillment][:messages][0][:payload][:partial] == "showfx"
        @render_partial = "fx"
      elsif response[:result][:fulfillment][:messages][0][:payload][:partial] == "showbene"
        puts check_login
        if check_login
          beneficiary
          @render_partial = "beneficiary"
        else
          @render_partial = "login"
        end
      elsif response[:result][:fulfillment][:messages][0][:payload][:partial] == "lasttrans"
         if check_login 
          previous
          @render_partial = "lasttrans"
        else
          @render_partial = "login"
        end
      end
    else
        speech_res = response[:result][:fulfillment][:messages][0][:speech]
    end


    if session[:session_id]
  		@message.session_id = session[:session_id]
  	else
  		o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
		  string = (0...50).map { o[rand(o.length)] }.join
  		@message.session_id = string
  		session[:session_id] = string
  	end
  	respond_to do |format|       
        if speech_res
          @message.save
          Message.create(:message => speech_res , :session_id => session[:session_id] , :from_id => "bot")
          format.js
        else
          format.js
        end
    end
  

  end
  
  def instarem_api(root_url, body_code = nil ,  auth_token = '0O1QCg+UcMLTHdfxHJllzWiUfWTw520EMifGt72vTDmRgMXZKJsx001K2Svelvuh' )  
    url = URI(root_url)
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url)
    request["authorization"] = 'amx ' + auth_token.to_s
    request["content-type"] = 'application/x-www-form-urlencoded'
    request["cache-control"] = 'no-cache'
    request["accept-encoding"] = "identity"
    if body_code 
      request.body = body_code
     end 
    return http.request(request)
  end

  def check_login
    url_send = "http://stagingapi.instarem.com/v1/api/v1/GetPayeeList"
    session_t = Session.where(:session_id => session[:session_id]).count
    if session_t !=0 
       auth_token = Session.where(:session_id => session[:session_id]).first(1).pluck(:auth_token)[0]
       puts auth_token
       response = instarem_api(url_send , nil , auth_token)
       puts response.read_body
       parsed = JSON.parse(response.read_body) 
       if parsed["responseData"] != nil
         return auth_token
        else 
          return false
       end
    else
          return false
    end
  end
  
  def login_instarem (root_url , body_code)
    url = URI(root_url)
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Post.new(url)
    request["authorization"] = 'amx 0O1QCg+UcMLTHdfxHJllzWiUfWTw520EMifGt72vTDmRgMXZKJsx001K2Svelvuh'
    request["accept-encoding"] = "identity"
    request["content-type"] = 'application/x-www-form-urlencoded'
    request["cache-control"] = 'no-cache'
    if body_code 
      request.body = body_code
     end 
    return http.request(request)
  end
  private

  def message_params
  	params.require(:message).permit(:message, :session_id , :from_id)
  end 
end
