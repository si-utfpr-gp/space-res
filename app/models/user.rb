class User < ApplicationRecord
  include Avatarable

  belongs_to :department, optional: true
  has_many :sessions, dependent: :destroy

  has_secure_password
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: RegexPatterns::EMAIL }
  validates :password, length: { minimum: 6 }, if: :password_digest_changed?
  validates :admin, inclusion: { in: [ true, false ] }
  # optional: true skips the existence check; this one refuses a new id that matches no department.
  validates :department, presence: true, if: -> { department_id_changed? && !department_id.nil? }

  scope :ordered_by_name, -> { order(:name) }
end
