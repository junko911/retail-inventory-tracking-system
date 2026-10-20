require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "index uses grouped counts instead of per-product association loads" do
    queries = capture_sql { get products_path }

    assert_response :success
    assert_select "td", text: products(:widget).name
    assert_equal 1, queries.count { |sql| sql.include?('FROM "tracking_events"') && sql.include?("COUNT") }
    assert_equal 1, queries.count { |sql| sql.include?('FROM "price_checks"') && sql.include?("COUNT") }
    assert_equal 0, queries.count { |sql| sql.match?(/FROM "tracking_events".*WHERE.*"product_id"/) }
  end

  test "show lists price checks for the product" do
    get product_path(products(:widget))

    assert_response :success
    assert_select "td", text: "$4.50"
    assert_select "a", text: "1 Bagshot Row, Hobbiton"
    assert_select "td", text: "$6.25", count: 0
  end

  test "show previews tracking events and links to the full list when truncated" do
    ApplicationController::PREVIEW_LIMIT.times do |i|
      TrackingEvent.create!(
        product: products(:widget),
        store: stores(:oak_avenue),
        inventory_present: false,
        event_time: Time.zone.parse("2026-04-01 10:00") + i.hours
      )
    end

    queries = capture_sql { get product_path(products(:widget)) }

    assert_response :success
    assert_select "a", text: "View all tracking events"
    assert_operator queries.count { |sql| sql.include?('FROM "tracking_events"') }, :<=, 3
    assert_operator queries.count { |sql| sql.include?('FROM "stores"') }, :<=, 2

    get tracking_events_path(product_id: products(:widget).id)
    assert_response :success
    assert_select "h1", "Tracking Events"
    assert_select "a", text: products(:widget).name
  end

  test "show links to all price checks when truncated" do
    ApplicationController::PREVIEW_LIMIT.times do |i|
      PriceCheck.create!(
        product: products(:widget),
        store: stores(:oak_avenue),
        price: 5 + i,
        event_time: Time.zone.parse("2026-04-01 10:00") + i.hours
      )
    end

    get product_path(products(:widget))

    assert_response :success
    assert_select "a", text: "View all price checks"

    get price_checks_path(product_id: products(:widget).id)
    assert_response :success
    assert_select "h1", "Price Checks"
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
