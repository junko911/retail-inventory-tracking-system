require "test_helper"

class PriceCheckTest < ActiveSupport::TestCase
  test "a valid price check saves" do
    price_check = PriceCheck.new(
      product: products(:widget),
      store: stores(:main_street),
      price: 4.50,
      event_time: Time.zone.parse("2026-05-01 12:00")
    )

    assert price_check.save
  end

  test "a price of zero is a valid observation" do
    price_check = PriceCheck.new(
      product: products(:widget),
      store: stores(:main_street),
      price: 0,
      event_time: Time.zone.parse("2026-05-02 12:00")
    )

    assert price_check.valid?
  end

  test "price is required" do
    price_check = PriceCheck.new(
      product: products(:widget),
      store: stores(:main_street),
      event_time: Time.zone.now
    )

    assert_not price_check.valid?
    assert_includes price_check.errors[:price], "can't be blank"
  end

  test "price cannot be negative" do
    price_check = PriceCheck.new(
      product: products(:widget),
      store: stores(:main_street),
      price: -1,
      event_time: Time.zone.now
    )

    assert_not price_check.valid?
    assert_includes price_check.errors[:price], "must be greater than or equal to 0"
  end

  test "event time is required" do
    price_check = PriceCheck.new(
      product: products(:widget),
      store: stores(:main_street),
      price: 4.50
    )

    assert_not price_check.valid?
    assert_includes price_check.errors[:event_time], "can't be blank"
  end

  test "saving a price check does not create a tracking event" do
    assert_no_difference "TrackingEvent.count" do
      PriceCheck.create!(
        product: products(:gadget),
        store: stores(:main_street),
        price: 9.99,
        event_time: Time.zone.parse("2026-06-01 08:00")
      )
    end
  end

  test "database rejects a negative price even when validations are skipped" do
    check = PriceCheck.create!(
      product: products(:widget),
      store: stores(:main_street),
      price: 1,
      event_time: Time.zone.now
    )

    assert_raises(ActiveRecord::StatementInvalid) { check.update_column(:price, -1) }
  end
end
