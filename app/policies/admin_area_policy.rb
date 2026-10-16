class AdminAreaPolicy
  def initialize(user)
    @user = user
  end

  def access?
    @user.admin?
  end
end
