class Notification < ApplicationRecord
  KIND_ENUM = {
    confirmation_email: 0,
  }.freeze

  belongs_to :user

  enum kind: KIND_ENUM

  scope :email_success, -> { where(delivery_status: "email_success") }

  def self.kinds; KIND_ENUM.keys.map(&:to_s) end

  def email_success?; delivery_status == "email_success" end
end