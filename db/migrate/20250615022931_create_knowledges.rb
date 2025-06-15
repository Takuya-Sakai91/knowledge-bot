class CreateKnowledges < ActiveRecord::Migration[7.1]
  def change
    create_table :knowledges do |t|
      t.string :category
      t.string :keyword
      t.text :content

      t.timestamps
    end
  end
end
