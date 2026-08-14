# frozen_string_literal: true

# Tracks one Razorpay order's payment lifecycle for an Order. A retry after
# a failed attempt reopens this same row (Razorpay itself allows more than
# one payment attempt against the same order_id) rather than creating a new
# one — the order only moves to `confirmed` once this reaches `captured`.
class Payment < ApplicationRecord
  belongs_to :order

  # `refund_pending` = the order behind this payment was cancelled after the
  # money was captured — flagged automatically, but the actual refund is a
  # manual admin action (Payments::Refund), never automatic.
  enum :status, { created: 0, authorized: 1, captured: 2, failed: 3, refunded: 4, refund_pending: 5 }, default: 0

  validates :razorpay_order_id, presence: true, uniqueness: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

  def amount
    amount_cents / 100.0
  end
end
