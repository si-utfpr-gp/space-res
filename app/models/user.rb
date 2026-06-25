class User < ApplicationRecord
  include Avatarable

  has_many :sessions, dependent: :destroy
  has_many :reservations
  has_many :approvals, foreign_key: :aprovador_id
  has_many :sectors_responsavel, class_name: "Sector", foreign_key: :responsavel_id

  has_secure_password
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: RegexPatterns::EMAIL }
  validates :password, length: { minimum: 6 }, if: :password_digest_changed?
end
