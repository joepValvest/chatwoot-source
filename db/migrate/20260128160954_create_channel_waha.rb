class CreateChannelWaha < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_waha do |t|
      t.string :phone_number, null: false
      t.string :waha_api_url, null: false
      t.string :waha_api_key, null: false
      t.string :session_name, default: 'default'
      t.jsonb :provider_config, default: {}
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_waha, :phone_number, unique: true
    add_index :channel_waha, :account_id
  end
end
