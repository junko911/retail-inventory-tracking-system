require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "show lists price checks for the product" do
    get product_path(products(:widget))

    assert_response :success
    assert_select "td", text: "$4.50"
    assert_select "a", text: "1 Bagshot Row, Hobbiton"
    assert_select "td", text: "$6.25", count: 0
  end

  test "show loads each tracking event store in one query" do
    TrackingEvent.create!(
      product: products(:widget),
      store: stores(:oak_avenue),
      inventory_present: false,
      event_time: Time.zone.parse("2026-04-01 10:00")
    )

    queries = capture_sql { get product_path(products(:widget)) }

    assert_response :success
    assert_equal 1, queries.count { |sql| sql.include?('FROM "tracking_events"') }
    assert_operator queries.count { |sql| sql.include?('FROM "stores"') }, :<=, 2
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
