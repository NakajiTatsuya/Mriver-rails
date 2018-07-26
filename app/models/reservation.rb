class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :listing
# 空欄で登録できないようにする
  # validates :start_date, presence: true  
  # validates :end_date, presence: true
end
