# frozen_string_literal: true

class Reservations::SpaceForm < BaseForm
  SPACES = [
    { id: 1, name: "Sala 101", kind: "Sala", capacity: 30, requires_approval: false }.freeze,
    { id: 2, name: "Lab de Informática", kind: "Laboratório", capacity: 20, requires_approval: true }.freeze,
    { id: 3, name: "Auditório", kind: "Auditório", capacity: 100, requires_approval: true }.freeze
  ].freeze

  attr_accessor :space_id

  validates :space_id, presence: true

  def spaces = SPACES

  def selected_space
    spaces.find { |space| space[:id].to_s == space_id.to_s }
  end

  def attributes
    { space_id: space_id }
  end

  def params
    [ :space_id ]
  end
end
