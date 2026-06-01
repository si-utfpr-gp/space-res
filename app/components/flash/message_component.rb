# frozen_string_literal: true

class Flash::MessageComponent < ViewComponent::Base
  def initialize(id: nil)
    @id = id || "flash_messages"
  end

  def messages
    helpers.flash.delete(:timedout)
  end

  def alert_css_classes(flash_type)
    "relative mb-4 flex w-full rounded-lg border-l-4 p-4 text-xs md:text-sm #{class_type(flash_type)}"
  end

  private

    def class_type(flash_type)
      { notice: "bg-blue-50 text-blue-800",
        alert: "bg-red-50 text-red-800",
        success: "bg-green-50 text-green-800",
        warning: "bg-yellow-50 text-yellow-800"
      }[flash_type.to_sym] || "alert-#{flash_type}"
    end
end
