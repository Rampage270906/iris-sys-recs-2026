class Post < ApplicationRecord
  belongs_to :user, optional: true

  # Thumbnail image & Resources
  has_one_attached :header_image
  has_many_attached :files

  validates :title, presence: true
end
