class Admin::HomeController < Admin::BaseController
  def index
    @campus_summaries = Admin::CampusSummariesQuery.new.call
  end
end
