# The texts that show a space in the administrative area, including the ones shown when an optional record is missing.
class Admin::SpacePresenter
  def initialize(space)
    @space = space
  end

  # "Guarapuava · Bloco B", or "Guarapuava · Sem bloco" for spaces outside buildings.
  def location
    [ @space.campus.name, building_name ].join(" · ")
  end

  def building_name
    @space.building&.name || I18n.t("admin.spaces.no_building")
  end

  def department_name
    @space.department&.name || I18n.t("admin.spaces.no_department")
  end

  def approval_label
    I18n.t(@space.requires_approval? ? "admin.spaces.approval.required" : "admin.spaces.approval.not_required")
  end

  # Who releases the reservations of the space, so the administrator does not need to know the rule beforehand.
  def approval_description
    return I18n.t("admin.spaces.approval.description.not_required") unless @space.requires_approval?
    return I18n.t("admin.spaces.approval.description.by_administrators") if @space.department.nil?

    I18n.t("admin.spaces.approval.description.by_department", department: @space.department.name)
  end

  def status_label
    I18n.t("admin.spaces.status.#{@space.status}")
  end
end
