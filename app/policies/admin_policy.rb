class AdminPolicy
  def initialize(user)
    @user = user
  end

  def access_area?
    @user.admin?
  end
end
