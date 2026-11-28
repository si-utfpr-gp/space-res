# The texts that show a space in the administrative area, including the ones shown when an optional record is missing.
class Admin::SpacePresenter
  def initialize(space)
    @space = space
  end

  def building_name
    @space.building&.name || I18n.t("admin.campi.spaces.no_building")
  end

  def department_name
    @space.department&.name || I18n.t("admin.campi.spaces.no_department")
  end

  def approval_label
    I18n.t(@space.requires_approval? ? "admin.campi.spaces.approval.required" : "admin.campi.spaces.approval.not_required")
  end

  # Who releases the reservations of the space, so the administrator does not need to know the rule beforehand.
  def approval_description
    return I18n.t("admin.campi.spaces.approval.description.not_required") unless @space.requires_approval?
    return I18n.t("admin.campi.spaces.approval.description.by_administrators") if @space.department.nil?

    I18n.t("admin.campi.spaces.approval.description.by_department", department: @space.department.name)
  end

  def status_label
    I18n.t("admin.campi.spaces.status.#{@space.status}")
  end
end
