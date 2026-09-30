namespace :users do
  desc "Grant super admin access to an existing user: bin/rails \"users:grant_super_admin[email@utfpr.edu.br]\""
  task :grant_super_admin, [ :email_address ] => :environment do |_task, args|
    user = User.find_by(email_address: args[:email_address])
    abort "User not found: #{args[:email_address]}" unless user

    user.update!(super_admin: true)
    puts "#{user.email_address} is now a super admin"
  end
end
