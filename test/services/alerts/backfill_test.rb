require "test_helper"

class Alerts::BackfillTest < ActiveSupport::TestCase
  test "rebuilds one alert per stockout streak without using create callbacks" do
    TrackingEvent.insert_all!([
      { product_id: products(:widget).id, store_id: stores(:main_street).id, inventory_present: false, event_time: Time.zone.parse("2026-07-01 09:00"), created_at: Time.current, updated_at: Time.current },
      { product_id: products(:widget).id, store_id: stores(:main_street).id, inventory_present: false, event_time: Time.zone.parse("2026-07-02 09:00"), created_at: Time.current, updated_at: Time.current },
      { product_id: products(:widget).id, store_id: stores(:main_street).id, inventory_present: false, event_time: Time.zone.parse("2026-07-03 09:00"), created_at: Time.current, updated_at: Time.current },
      { product_id: products(:widget).id, store_id: stores(:main_street).id, inventory_present: true, event_time: Time.zone.parse("2026-07-04 09:00"), created_at: Time.current, updated_at: Time.current },
      { product_id: products(:widget).id, store_id: stores(:main_street).id, inventory_present: false, event_time: Time.zone.parse("2026-07-05 09:00"), created_at: Time.current, updated_at: Time.current },
      { product_id: products(:gadget).id, store_id: stores(:oak_avenue).id, inventory_present: false, event_time: Time.zone.parse("2026-07-01 09:00"), created_at: Time.current, updated_at: Time.current },
      { product_id: products(:gadget).id, store_id: stores(:oak_avenue).id, inventory_present: false, event_time: Time.zone.parse("2026-07-02 09:00"), created_at: Time.current, updated_at: Time.current }
    ])

    assert_difference -> { Alert.count }, 2 do
      assert_equal 2, Alerts::Backfill.call
    end

    pony = Alert.find_by!(product: products(:widget), store: stores(:main_street))
    assert_equal brands(:one), pony.brand
    assert_equal Time.zone.parse("2026-07-01 09:00"), pony.opening_tracking_event.event_time
    assert_equal Time.zone.parse("2026-07-02 09:00"), pony.confirming_tracking_event.event_time

    frogs = Alert.find_by!(product: products(:gadget), store: stores(:oak_avenue))
    assert_equal brands(:two), frogs.brand
  end
end
