require "test_helper"

class StoresControllerTest < ActionDispatch::IntegrationTest
  test "index uses grouped counts instead of per-store association loads" do
    queries = capture_sql { get stores_path }

    assert_response :success
    assert_equal 1, queries.count { |sql| sql.include?('FROM "tracking_events"') && sql.include?("COUNT") }
    assert_equal 1, queries.count { |sql| sql.include?('FROM "price_checks"') && sql.include?("COUNT") }
  end

  test "show lists price checks for the store" do
    get store_path(stores(:main_street))

    assert_response :success
    assert_select "td", text: "$4.50"
    assert_select "a", text: "Bree-Brewed Ale"
    assert_select "td", text: "$6.25", count: 0
  end

  test "show previews tracking events and links to the full list when truncated" do
    second_product = Product.create!(name: "Second Ale", brand: brands(:two))
    ApplicationController::PREVIEW_LIMIT.times do |i|
      TrackingEvent.create!(
        store: stores(:main_street),
        product: second_product,
        inventory_present: false,
        event_time: Time.zone.parse("2026-04-01 10:00") + i.hours
      )
    end

    queries = capture_sql { get store_path(stores(:main_street)) }

    assert_response :success
    assert_select "a", text: "View all tracking events"
    assert_operator queries.count { |sql| sql.include?('FROM "tracking_events"') }, :<=, 3
    assert_operator queries.count { |sql| sql.include?('FROM "products"') }, :<=, 2
    assert_operator queries.count { |sql| sql.include?('FROM "brands"') }, :<=, 2

    get tracking_events_path(store_id: stores(:main_street).id)
    assert_response :success
    assert_select "a", text: stores(:main_street).address
  end

  private

  def capture_sql
    queries = []
    callback = lambda do |*, payload|
      sql = payload[:sql]
      next if payload[:name] == "SCHEMA" || sql.match?(/TRANSACTION|SAVEPOINT/)

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    queries
  end
end
