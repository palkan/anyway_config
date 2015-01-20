class AddTestos < ActiveRecord::Migration
 def self.up
    create_table :testos do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :testos
  end
end
