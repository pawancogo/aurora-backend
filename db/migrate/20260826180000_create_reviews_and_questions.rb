# frozen_string_literal: true

class CreateReviewsAndQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :rating_avg, :decimal, precision: 3, scale: 2, null: false, default: 0
    add_column :products, :rating_count, :integer, null: false, default: 0
    add_column :products, :rating_distribution, :jsonb, null: false, default: {}

    create_table :reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string :title
      t.text :body, null: false
      t.integer :status, null: false, default: 0
      t.boolean :verified_purchase, null: false, default: false
      t.integer :helpful_count, null: false, default: 0
      t.text :admin_response
      t.datetime :responded_at
      t.datetime :published_at
      t.timestamps
    end
    add_index :reviews, [ :product_id, :customer_id ], unique: true
    add_index :reviews, [ :product_id, :status ]
    add_index :reviews, :status

    create_table :review_images do |t|
      t.references :review, null: false, foreign_key: true
      t.string :url, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :review_votes do |t|
      t.references :review, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.timestamps
    end
    add_index :review_votes, [ :review_id, :customer_id ], unique: true

    create_table :product_questions do |t|
      t.references :product, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.text :body, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :product_questions, [ :product_id, :status ]
    add_index :product_questions, :status

    create_table :product_answers do |t|
      t.references :product_question, null: false, foreign_key: true
      t.references :customer, foreign_key: true
      t.references :admin_user, foreign_key: true
      t.text :body, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :product_answers, [ :product_question_id, :status ]
  end
end
