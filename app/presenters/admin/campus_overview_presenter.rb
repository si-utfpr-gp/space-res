# The sentences of the summaries on the campus overview.
class Admin::CampusOverviewPresenter
  def initialize(space_counts:, building_names:)
    @space_counts = space_counts
    @building_names = building_names
  end

  def spaces_count
    @space_counts.values.sum
  end

  # "5 disponíveis, 1 indisponível e 1 desativado.", leaving out the statuses without spaces.
  def spaces_summary
    return I18n.t("admin.campi.show.spaces_summary.empty") if spaces_count.zero?

    parts = Space.statuses.keys.filter_map do |status|
      count = @space_counts.fetch(status, 0)
      I18n.t("admin.campi.show.spaces_by_status.#{status}", count:) if count.positive?
    end
    I18n.t("admin.campi.show.sentence", list: parts.to_sentence)
  end

  def buildings_count
    @building_names.size
  end

  # "Bloco B, Bloco C e Bloco R."
  def buildings_summary
    return I18n.t("admin.campi.show.buildings_summary.empty") if @building_names.empty?

    I18n.t("admin.campi.show.sentence", list: @building_names.to_sentence)
  end
end
