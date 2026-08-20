# frozen_string_literal: true

class Reservations::ScheduleForm < BaseForm
  RESERVATION_TYPES = %w[unica recorrente].freeze
  FREQUENCIES = %w[weekly biweekly monthly].freeze
  WEEK_DAYS = %w[monday tuesday wednesday thursday friday saturday].freeze
  TIME_SLOTS = {
    morning: [
      [ "M1", "07:30 – 08:20" ].freeze,
      [ "M2", "08:20 – 09:10" ].freeze,
      [ "M3", "09:10 – 10:00" ].freeze,
      [ "M4", "10:20 – 11:10" ].freeze,
      [ "M5", "11:10 – 12:00" ].freeze,
      [ "M6", "12:00 – 12:50" ].freeze
    ].freeze,
    afternoon: [
      [ "T1", "13:00 – 13:50" ].freeze,
      [ "T2", "13:50 – 14:40" ].freeze,
      [ "T3", "14:40 – 15:30" ].freeze,
      [ "T4", "15:50 – 16:40" ].freeze,
      [ "T5", "16:40 – 17:30" ].freeze,
      [ "T6", "17:30 – 18:20" ].freeze
    ].freeze,
    evening: [
      [ "N1", "18:40 – 19:30" ].freeze,
      [ "N2", "19:30 – 20:20" ].freeze,
      [ "N3", "20:20 – 21:10" ].freeze,
      [ "N4", "21:20 – 22:10" ].freeze,
      [ "N5", "22:10 – 23:00" ].freeze
    ].freeze
  }.freeze

  attr_accessor :tipo_reserva, :datas, :data_inicio, :data_fim, :frequencia, :dias, :horarios

  validates :tipo_reserva, presence: true, inclusion: { in: RESERVATION_TYPES, allow_blank: true }
  validates :data_inicio, :data_fim, :frequencia, presence: true, if: :recurring?
  validate :single_date_is_present, if: :single?
  validate :week_days_are_present, if: :recurring?
  validate :time_slots_are_present, if: :known_reservation_type?

  def attributes
    {
      tipo_reserva: tipo_reserva,
      datas: datas,
      data_inicio: data_inicio,
      data_fim: data_fim,
      frequencia: frequencia,
      dias: dias,
      horarios: horarios
    }
  end

  def params
    [ :tipo_reserva, :data_inicio, :data_fim, :frequencia, datas: [], dias: [], horarios: [] ]
  end

  def reservation_types = RESERVATION_TYPES
  def frequencies = FREQUENCIES
  def week_days = WEEK_DAYS
  def time_slots = TIME_SLOTS

  def single? = tipo_reserva == "unica"
  def recurring? = tipo_reserva == "recorrente"

  private

  def known_reservation_type?
    RESERVATION_TYPES.include?(tipo_reserva)
  end

  def single_date_is_present
    add_blank_collection_error(:datas)
  end

  def week_days_are_present
    add_blank_collection_error(:dias)
  end

  def time_slots_are_present
    add_blank_collection_error(:horarios)
  end

  def add_blank_collection_error(attribute)
    errors.add(attribute, :blank) if Array(public_send(attribute)).all?(&:blank?)
  end
end
