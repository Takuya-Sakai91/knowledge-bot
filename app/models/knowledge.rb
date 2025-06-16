class Knowledge < ApplicationRecord
  validates :content, presence: true

  scope :search, ->(keyword) { where("content LIKE ?", "%#{keyword}%") }

  def self.categories
    distinct.pluck(:category).compact.sort
  end
end
