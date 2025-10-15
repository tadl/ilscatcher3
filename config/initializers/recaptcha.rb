if Settings.has_captcha == true
  Recaptcha.configure do |c|
    c.site_key   = ENV['RECAPTCHA_SITE_KEY']
    c.secret_key = ENV['RECAPTCHA_SECRET_KEY']
  end
end