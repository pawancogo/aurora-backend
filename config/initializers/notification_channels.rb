# frozen_string_literal: true

# Register delivery adapters. Add a new service by writing Channels::X and
# registering it here — Notify/Catalog do not need to know the provider.
Rails.application.config.to_prepare do
  Notifications::Registry.reset!
  Notifications::Registry.register(Notifications::Channels::Email.new)
  Notifications::Registry.register(Notifications::Channels::Sms.new)
  Notifications::Registry.register(Notifications::Channels::Push.new)
end
