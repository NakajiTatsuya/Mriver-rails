class RenamePetTypeColumnToListings < ActiveRecord::Migration[5.0]
  def change
    rename_column :listings, :pet_type, :instrument_type
  end
end
