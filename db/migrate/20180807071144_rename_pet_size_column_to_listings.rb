class RenamePetSizeColumnToListings < ActiveRecord::Migration[5.0]
  def change
    rename_column :listings, :pet_size, :level
  end
end
