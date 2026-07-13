class Reservations::SpaceForm < BaseForm
  attr_accessor :space_id

  def attributes
    { space_id: space_id }
  end

  def params
    [:space_id]
  end
end