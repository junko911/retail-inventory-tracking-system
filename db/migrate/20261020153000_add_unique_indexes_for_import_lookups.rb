class AddUniqueIndexesForImportLookups < ActiveRecord::Migration[7.1]
  def change
    # CSV import looks up stores by address and products by name only, so those
    # values must be unique. Brand names are unique for the same reason.
    add_index :brands, :name, unique: true
    add_index :stores, :address, unique: true
    add_index :products, :name, unique: true
  end
end
