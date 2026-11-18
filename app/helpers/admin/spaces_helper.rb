module Admin::SpacesHelper
  # "Guarapuava · Bloco B", or "Guarapuava · Sem bloco" for spaces outside buildings.
  def space_location(space)
    [ space.campus.name, space_building_name(space) ].join(" · ")
  end

  def space_building_name(space)
    space.building&.name || t("admin.spaces.no_building")
  end

  def space_department_name(space)
    space.department&.name || t("admin.spaces.no_department")
  end

  def space_approval_label(space)
    t(space.requires_approval? ? "admin.spaces.approval.required" : "admin.spaces.approval.not_required")
  end

  # Who releases the reservations of the space, so the administrator does not need to know the rule beforehand.
  def space_approval_description(space)
    return t("admin.spaces.approval.description.not_required") unless space.requires_approval?
    return t("admin.spaces.approval.description.by_administrators") if space.department.nil?

    t("admin.spaces.approval.description.by_department", department: space.department.name)
  end

  def space_status_label(space)
    t("admin.spaces.status.#{space.status}")
  end
end
