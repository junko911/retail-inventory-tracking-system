require "test_helper"

class AlertTest < ActiveSupport::TestCase
  test "two consecutive no-inventory events alert the product brand" do
    first = track(inventory_present: false, event_time: "2026-04-01 09:00")
    second = track(inventory_present: false, event_time: "2026-04-02 09:00")

    assert_equal 1, Alert.where(product: products(:widget), store: stores(:main_street)).count
    alert = Alert.find_by!(product: products(:widget), store: stores(:main_street))
    assert_equal brands(:one), alert.brand
    assert_equal first, alert.opening_tracking_event
    assert_equal second, alert.confirming_tracking_event
    assert_equal second.event_time, alert.triggered_at
  end

  test "a single no-inventory event does not alert" do
    track(inventory_present: false, event_time: "2026-04-01 09:00")

    assert_empty Alert.where(product: products(:widget), store: stores(:main_street))
  end

  test "inventory present between two stockouts prevents an alert" do
    track(inventory_present: false, event_time: "2026-04-01 09:00")
    track(inventory_present: true, event_time: "2026-04-02 09:00")
    track(inventory_present: false, event_time: "2026-04-03 09:00")

    assert_empty Alert.where(product: products(:widget), store: stores(:main_street))
  end

  test "a longer stockout stays one alert" do
    track(inventory_present: false, event_time: "2026-04-01 09:00")
    track(inventory_present: false, event_time: "2026-04-02 09:00")
    track(inventory_present: false, event_time: "2026-04-03 09:00")

    assert_equal 1, Alert.where(product: products(:widget), store: stores(:main_street)).count
  end

  test "inventory returning starts a new streak that can alert again" do
    track(inventory_present: false, event_time: "2026-04-01 09:00")
    track(inventory_present: false, event_time: "2026-04-02 09:00")
    track(inventory_present: true, event_time: "2026-04-03 09:00")
    track(inventory_present: false, event_time: "2026-04-04 09:00")
    track(inventory_present: false, event_time: "2026-04-05 09:00")

    assert_equal 2, Alert.where(product: products(:widget), store: stores(:main_street)).count
  end

  test "consecutive stockouts at another store do not alert this store" do
    track(inventory_present: false, event_time: "2026-04-01 09:00", store: stores(:main_street))
    track(inventory_present: false, event_time: "2026-04-02 09:00", store: stores(:oak_avenue))

    assert_empty Alert.where(product: products(:widget))
  end

  test "events saved out of event_time order still alert once" do
    track(inventory_present: false, event_time: "2026-04-03 09:00")
    track(inventory_present: false, event_time: "2026-04-01 09:00")

    alerts = Alert.where(product: products(:widget), store: stores(:main_street))
    assert_equal 1, alerts.count
    assert_equal Time.zone.parse("2026-04-01 09:00"), alerts.first.opening_tracking_event.event_time
  end

  test "a later in-stock event between the pair removes the alert" do
    track(inventory_present: false, event_time: "2026-04-01 09:00")
    track(inventory_present: false, event_time: "2026-04-03 09:00")
    track(inventory_present: true, event_time: "2026-04-02 09:00")

    assert_empty Alert.where(product: products(:widget), store: stores(:main_street))
  end

  test "the same event time uses id as the tie breaker" do
    track(inventory_present: false, event_time: "2026-04-01 09:00")
    track(inventory_present: false, event_time: "2026-04-01 09:00")

    assert_equal 1, Alert.where(product: products(:widget), store: stores(:main_street)).count
  end

  private

  def track(inventory_present:, event_time:, store: stores(:main_street), product: products(:widget))
    TrackingEvent.create!(
      store: store,
      product: product,
      inventory_present: inventory_present,
      event_time: Time.zone.parse(event_time)
    )
  end
end
