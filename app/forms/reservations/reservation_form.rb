class Reservations::ReservationForm
  include ActiveModel::Model

  STEPS = [ :space, :schedule, :confirmation ].freeze
  EDITABLE_STEPS = STEPS.first(2).freeze

  attr_reader :current_step
  attr_accessor :user

  def initialize(user:, current_step: nil, attributes: {})
    @user = user
    @attributes = attributes.to_h.deep_symbolize_keys.slice(*EDITABLE_STEPS)
    @current_step = current_step&.to_sym
  end

  def completed? = earliest_incomplete_step == :confirmation
  def final_step? = current_step == EDITABLE_STEPS.last

  def update_step(step, attributes)
    step = step.to_sym
    new_attributes = attributes.to_h.deep_symbolize_keys
    clear_steps_after(step) if @attributes[step] != new_attributes
    @attributes[step] = new_attributes
    @current_form = build_form(step)
    @current_form.valid?
  end

  def current_form
    @current_form ||= build_form(current_step)
  end

  def form_for(step)
    build_form(step.to_sym)
  end

  def earliest_incomplete_step
    EDITABLE_STEPS.find { |step| !form_for(step).valid? } || :confirmation
  end

  def prerequisite_for(step)
    requested_index = STEPS.index(step.to_sym)
    EDITABLE_STEPS.first(requested_index).find { |candidate| !form_for(candidate).valid? }
  end

  def step_complete?(step)
    step == :confirmation ? completed? : form_for(step).valid?
  end

  def next_step
    STEPS.fetch(STEPS.index(current_step) + 1)
  end

  def previous_step
    index = STEPS.index(current_step)
    index&.positive? ? STEPS[index - 1] : nil
  end

  def selected_space
    form_for(:space).selected_space
  end

  def schedule
    form_for(:schedule)
  end

  def to_session
    @attributes.deep_dup
  end

  private

  def clear_steps_after(step)
    following_steps = EDITABLE_STEPS.drop(EDITABLE_STEPS.index(step) + 1)
    @attributes.except!(*following_steps)
  end

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
