# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :email_marketing, :boolean, null: false, default: true
    add_column :customers, :unsubscribe_token, :string
    add_index :customers, :unsubscribe_token, unique: true

    reversible do |dir|
      dir.up do
        say_with_time "backfill customer unsubscribe tokens" do
          Customer.reset_column_information
          Customer.where(unsubscribe_token: nil).find_each do |customer|
            customer.update_columns(unsubscribe_token: SecureRandom.urlsafe_base64(24))
          end
          change_column_null :customers, :unsubscribe_token, false
        end
      end
    end

    create_table :notifications do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :event_key, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.string :url
      t.datetime :read_at
      t.references :notifiable, polymorphic: true, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
    add_index :notifications, [ :customer_id, :created_at ]
    add_index :notifications, [ :customer_id, :read_at ]
    add_index :notifications, [ :customer_id, :event_key, :notifiable_type, :notifiable_id ],
              unique: true, name: "idx_notifications_unique_event"

    create_table :notification_deliveries do |t|
      t.references :notification, null: false, foreign_key: true
      t.string :channel, null: false
      t.integer :status, null: false, default: 0
      t.text :error
      t.datetime :sent_at
      t.timestamps
    end
    add_index :notification_deliveries, [ :notification_id, :channel ], unique: true

    create_table :notification_preferences do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :event_key, null: false
      t.string :channel, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :notification_preferences, [ :customer_id, :event_key, :channel ],
              unique: true, name: "idx_notification_prefs_unique"
  end
end
