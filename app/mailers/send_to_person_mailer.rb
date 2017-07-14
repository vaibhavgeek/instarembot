class SendToPersonMailer < ApplicationMailer
  default from: "bot@instarem.com"
 def sample_email(body_details)
 	@body_details = body_details
    mail(to: 'gsoni@instarem.com', subject: 'Customer Support Inquiry')
  end
end
