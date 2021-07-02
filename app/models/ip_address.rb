# == Schema Information
#
# Table name: ip_addresses
#
#  id         :integer          not null, primary key
#  ip_pool_id :integer
#  ipv4       :string(255)
#  ipv6       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  hostname   :string(255)
#  priority   :integer
#

class IPAddress < ApplicationRecord

  belongs_to :ip_pool

  validates :ipv4, :presence => true, :uniqueness => true
  validates :hostname, :presence => true
  validates :ipv6, :uniqueness => {:allow_blank => true}

end
