module Avatarable
  extend ActiveSupport::Concern

  ACCEPTED_AVATAR_TYPES = %w[image/png image/jpg image/jpeg]
  ACCEPTED_AVATAR_TYPES_TEXT = ACCEPTED_AVATAR_TYPES.join(", ")

  included do
    has_one_attached :avatar

    validates :avatar, content_type: ACCEPTED_AVATAR_TYPES, size: { maximum: 5.megabytes }, if: :avatar_attached?
  end

  def avatar_attached?
    avatar.attached?
  end

  def avatar_url
    return ActionController::Base.helpers.asset_url("avatars/default_avatar.png") unless avatar_attached?
    Rails.application.routes.url_helpers.rails_blob_url(avatar)
  end
end
