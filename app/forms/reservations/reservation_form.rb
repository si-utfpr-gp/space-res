class Reservations::ReservationForm
  include ActiveModel::Model

  STEPS = [:space, :schedule, :confirmation].freeze

  attr_reader :current_step
  attr_accessor :user

  def initialize(user:, attributes: {})
    @user = user
    @attributes = attributes.deep_symbolize_keys
    @current_step = (@attributes[:current_step] || :space).to_sym
  end

  def completed? = current_step == :confirmation
  def final_step? = current_step == STEPS[-2]
  def form_index = STEPS.index(current_step) + 1

  def move_to_next_step
    return if completed?
    @current_step = STEPS[STEPS.index(current_step) + 1]
    @attributes[:current_step] = @current_step
  end

  def move_to_previous_step
    return if current_step == STEPS.first
    @current_step = STEPS[STEPS.index(current_step) - 1]
    @attributes[:current_step] = @current_step
  end

  delegate :valid?, to: :current_form

  def update(attributes)
    @attributes[current_step] = attributes.to_h.symbolize_keys
    current_form.assign_attributes(attributes)
    valid?
  end

  def current_form
    @current_form ||= build_form(current_step)
  end

  def to_session
    @attributes
  end

  def save
    Reservation.create!(
      user: @user,
      space_id: @attributes.dig(:space, :space_id),
      tipo_reserva: @attributes.dig(:schedule, :tipo_reserva),
      status: "draft"
    )
  end

  private

  def build_form(step)
    return nil if step == :confirmation
    data = @attributes[step] || {}
    case step
    when :space    then Reservations::SpaceForm.new(data)
    when :schedule then Reservations::ScheduleForm.new(data)
    else raise "Invalid step: #{step}"
    end
  end
end