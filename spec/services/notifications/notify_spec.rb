# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::Notify do
  include ActiveJob::TestHelper

  let(:customer) { create(:customer) }
  let(:order) { create(:order, customer: customer, total_cents: 1999) }

  def notify!(event = "order.placed", extra = {})
    described_class.call(
      event: event,
      recipient: customer,
      notifiable: order,
      payload: Notifications::Payload.for_order(order).merge(extra.stringify_keys)
    )
  end

  it "creates an in-app notification and enqueues email delivery" do
    expect { notify! }.to have_enqueued_job(Notifications::DeliverJob)

    notification = customer.notifications.last
    expect(notification.event_key).to eq("order.placed")
    expect(notification.title).to eq("Order placed")
    expect(notification.body).to include(order.order_number)
    expect(notification.body).to include("₹19.99")
    expect(notification.deliveries.sole.channel).to eq("email")
    expect(notification.deliveries.sole).to be_pending
  end

  it "sends email through the existing ActionMailer path when the job runs" do
    perform_enqueued_jobs { notify!("order.confirmed") }

    mail = ActionMailer::Base.deliveries.last
    expect(mail).to be_present
    expect(mail.to).to eq([ customer.email ])
    expect(mail.subject).to eq("Payment confirmed")
    expect(mail.body.encoded).to include(order.order_number)
    expect(NotificationDelivery.last).to be_sent
  end

  it "is idempotent for the same customer, event, and record" do
    first = notify!
    expect { notify! }.not_to have_enqueued_job(Notifications::DeliverJob)
    expect(customer.notifications.where(event_key: "order.placed")).to contain_exactly(first)
  end

  it "skips optional email when the customer unsubscribed from marketing" do
    customer.update!(email_marketing: false)

    expect { notify!("review.request") }.not_to have_enqueued_job(Notifications::DeliverJob)
    expect(customer.notifications.last.event_key).to eq("review.request")
    expect(customer.notifications.last.deliveries).to be_empty
  end

  it "still sends transactional email after a marketing unsubscribe" do
    customer.update!(email_marketing: false)

    expect { notify!("order.shipped") }.to have_enqueued_job(Notifications::DeliverJob)
  end

  it "delivers email inline when Redis cannot enqueue the job" do
    allow(Notifications::DeliverJob).to receive(:perform_later).and_raise(RedisClient::CannotConnectError)
    allow(Notifications::DeliverJob).to receive(:perform_now).and_call_original

    perform_enqueued_jobs { notify! }

    expect(Notifications::DeliverJob).to have_received(:perform_now)
    expect(ActionMailer::Base.deliveries.last.subject).to eq("Order placed")
    expect(NotificationDelivery.last).to be_sent
  end

  it "does not fan out SMS until that adapter is configured" do
    allow(Notifications::Catalog).to receive(:fetch!).and_wrap_original do |method, key|
      method.call(key).merge(channels: %i[in_app email sms])
    end
    create(:notification_preference, customer: customer, event_key: "order.placed", channel: "sms", enabled: true)

    notify!
    expect(NotificationDelivery.where(channel: "sms")).to be_empty
    expect(NotificationDelivery.where(channel: "email")).to exist
  end

  it "delivers via a newly registered channel without changing Notify" do
    adapter = Class.new(Notifications::Channels::Base) do
      def key = "pager"
      def enabled? = true
      def deliver(delivery)
        delivery.notification.update!(payload: delivery.notification.payload.merge("paged" => true))
      end
    end.new
    Notifications::Registry.register(adapter)
    allow(Notifications::Catalog).to receive(:fetch!).and_wrap_original do |method, key|
      method.call(key).merge(channels: %i[in_app email pager])
    end

    perform_enqueued_jobs { notify! }

    expect(NotificationDelivery.find_by(channel: "pager")).to be_sent
    expect(customer.notifications.last.payload["paged"]).to be true
  ensure
    Notifications::Registry.adapters.delete("pager")
  end
end
