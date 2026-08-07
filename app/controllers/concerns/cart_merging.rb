# frozen_string_literal: true

# Folds a guest cart (identified by the X-Cart-Token header) into a customer's
# cart the moment they become authenticated (login, or email-verify auto-login).
module CartMerging
  private

  def merge_guest_cart!(customer)
    token = request.headers["X-Cart-Token"].presence
    return unless token

    guest_cart = Cart.find_by(token: token, customer_id: nil)
    return unless guest_cart

    customer_cart = Cart.find_or_create_by!(customer: customer)
    Carts::Manager.new(customer_cart).merge(guest_cart)
  end
end
