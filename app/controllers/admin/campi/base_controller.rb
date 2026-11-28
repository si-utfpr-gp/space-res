# The pages inside one campus. The campus comes from the URL, and its registrations are always
# looked up through it, so a building or space of another campus is not found.
class Admin::Campi::BaseController < Admin::BaseController
  layout "admin/campus"
  before_action :set_campus, :require_campus_access
  helper_method :campus_section

  private

    def set_campus
      @campus = Campus.find(params.expect(:campus_id))
    end

    # The section of the campus menu the page belongs to.
    def campus_section
      raise NotImplementedError, "#{self.class} must tell its campus section"
    end

    def set_breadcrumbs
      add_breadcrumb @campus.name, admin_campus_path(@campus)
    end
end
