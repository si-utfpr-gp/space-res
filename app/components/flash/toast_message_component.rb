# frozen_string_literal: true

class Flash::ToastMessageComponent < ViewComponent::Base
  def initialize(id: nil)
    @id = id || "flash"
  end

  def messages
    helpers.flash.delete(:timedout)
  end
end
