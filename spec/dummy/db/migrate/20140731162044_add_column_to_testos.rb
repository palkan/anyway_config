class AddColumnToTestos < ActiveRecord::Migration
  def change
    add_column :testos, :receipt_id, :integer
  end
end
