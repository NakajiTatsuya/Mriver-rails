class RenameBreedingYearsColumnToListings < ActiveRecord::Migration[5.0]
  def change
    rename_column :listings, :breeding_years, :instrument_years
  end
end
