require "test_helper"

class AlertsControllerTest < ActionDispatch::IntegrationTest
  test "index lists alerts for consecutive stockouts" do
    TrackingEvent.create!(product: products(:widget), store: stores(:main_street), inventory_present: false, event_time: Time.zone.parse("2026-05-01 09:00"))
    TrackingEvent.create!(product: products(:widget), store: stores(:main_street), inventory_present: false, event_time: Time.zone.parse("2026-05-02 09:00"))

    get alerts_path

    assert_response :success
    assert_select "h1", "Alerts"
    assert_select "a", text: "The Prancing Pony"
    assert_select "a", text: "Bree-Brewed Ale"
    assert_select "a", text: "1 Bagshot Row, Hobbiton"
    assert_select "td", text: "2026-05-02 09:00"
  end

  test "show displays the two no-inventory events" do
    TrackingEvent.create!(product: products(:widget), store: stores(:main_street), inventory_present: false, event_time: Time.zone.parse("2026-05-01 09:00"))
    TrackingEvent.create!(product: products(:widget), store: stores(:main_street), inventory_present: false, event_time: Time.zone.parse("2026-05-02 09:00"))
    alert = Alert.find_by!(product: products(:widget), store: stores(:main_street))

    get alert_path(alert)

    assert_response :success
    assert_select "h1", "Stockout Alert"
    assert_select "td", text: "2026-05-01 09:00"
    assert_select "td", text: "2026-05-02 09:00"
  end

  test "brand page lists alerts for that brand only" do
    TrackingEvent.create!(product: products(:widget), store: stores(:main_street), inventory_present: false, event_time: Time.zone.parse("2026-05-01 09:00"))
    TrackingEvent.create!(product: products(:widget), store: stores(:main_street), inventory_present: false, event_time: Time.zone.parse("2026-05-02 09:00"))
    TrackingEvent.create!(product: products(:gadget), store: stores(:oak_avenue), inventory_present: false, event_time: Time.zone.parse("2026-05-01 09:00"))
    TrackingEvent.create!(product: products(:gadget), store: stores(:oak_avenue), inventory_present: false, event_time: Time.zone.parse("2026-05-02 09:00"))

    get brand_path(brands(:one))

    assert_response :success
    assert_select "a", text: "Bree-Brewed Ale"
    assert_select "a", text: "Chocolate Frogs", count: 0
  end
end
