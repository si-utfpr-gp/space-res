require "test_helper"

class UserValidationsTest < ActiveSupport::TestCase
  subject { @user }
  setup do
    @user = create(:user)
  end

  should validate_presence_of(:name)
  should validate_presence_of(:email_address)
  should validate_uniqueness_of(:email_address).case_insensitive
end
