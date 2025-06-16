class RemoveKeywordFromKnowledges < ActiveRecord::Migration[7.1]
  def change
    remove_column :knowledges, :keyword, :string
  end
end
