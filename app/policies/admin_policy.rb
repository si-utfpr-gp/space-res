class AdminPolicy
  def initialize(user)
    @user = user
  end

  def access_area?
    @user.admin?
  end

  # The campus in the URL is only accepted for who may manage it. Until campus administrators
  # exist (#93), only the general administrator manages campi, and manages all of them.
  def manage_campus?(_campus)
    @user.admin?
  end
end
