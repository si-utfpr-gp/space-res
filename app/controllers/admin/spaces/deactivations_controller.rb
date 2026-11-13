# Permanent deactivation: the space is no longer listed for reservation. Reactivating undoes a mistake.
class Admin::Spaces::DeactivationsController < Admin::Spaces::BaseController
  def create
    @space.deactivate
    redirect_to admin_space_path(@space), success: t(".success"), status: :see_other
  end

  def destroy
    @space.reactivate
    redirect_to admin_space_path(@space), success: t(".success"), status: :see_other
  end
end
