class Approval < ApplicationRecord
  belongs_to :reservation
  belongs_to :sector
  belongs_to :aprovador, class_name: "User"
end
