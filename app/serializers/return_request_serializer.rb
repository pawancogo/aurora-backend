# frozen_string_literal: true

class ReturnRequestSerializer
  def self.collection(requests)
    requests.map { |request| new(request).as_json }
  end

  def initialize(request)
    @request = request
  end

  def as_json(*)
    {
      id: @request.id,
      rma_number: @request.rma_number,
      status: @request.status,
      resolution: @request.resolution,
      reason: @request.reason,
      admin_notes: @request.admin_notes,
      order_id: @request.order_id,
      order_number: @request.order.order_number,
      created_at: @request.created_at,
      decided_at: @request.decided_at,
      received_at: @request.received_at,
      completed_at: @request.completed_at,
      items: @request.return_items.map { |item| item_json(item) }
    }
  end

  def summary_json
    {
      id: @request.id,
      rma_number: @request.rma_number,
      status: @request.status,
      resolution: @request.resolution
    }
  end

  private

  def item_json(item)
    order_item = item.order_item
    {
      id: item.id,
      order_item_id: item.order_item_id,
      product_name: order_item.product_name,
      quantity: item.quantity,
      restocked: item.restocked
    }
  end
end
