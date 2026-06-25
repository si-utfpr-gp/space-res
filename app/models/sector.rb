class Sector < ApplicationRecord
  belongs_to :responsavel, class_name: "User"
  has_many :spaces
  has_many :approvals
end
