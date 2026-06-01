module RegexPatterns
  CELL_PHONE = /\A\(\d{2}\)\s\d\s\d{4}-\d{4}\z/.freeze
  EMAIL = URI::MailTo::EMAIL_REGEXP
  E164_PHONE = /\A\+[1-9]\d{9,14}\z/.freeze
end
