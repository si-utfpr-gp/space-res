# Permanent deactivation: the space is no longer listed for reservation. Reactivating undoes a mistake.
class Admin::Campi::Spaces::DeactivationsController < Admin::Campi::Spaces::BaseController
  def create
    @space.deactivate
    redirect_to admin_campus_space_path(@campus, @space), success: t(".success"), status: :see_other
  end

  def destroy
    @space.reactivate
    redirect_to admin_campus_space_path(@campus, @space), success: t(".success"), status: :see_other
  end
end
