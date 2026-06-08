class LegalController < ApplicationController
  layout "session"

  allow_unauthenticated_access only: %i[ terms ]

  def terms
  end
end
