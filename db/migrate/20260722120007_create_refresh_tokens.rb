# frozen_string_literal: true

class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens do |t|
      t.string :owner_type, null: false
      t.bigint :owner_id, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :refresh_tokens, %i[owner_type owner_id]
    add_index :refresh_tokens, :token_digest, unique: true
    add_index :refresh_tokens, :expires_at
  end
end
