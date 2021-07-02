class AddPriorityToIPAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :ip_addresses, :priority, :integer
  end
end
