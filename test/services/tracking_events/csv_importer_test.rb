require "test_helper"
require "tempfile"

class TrackingEvents::CsvImporterTest < ActiveSupport::TestCase
  setup do
    Alert.delete_all
    TrackingEvent.delete_all
  end

  test "bulk inserts events and rebuilds alerts without per-row create callbacks" do
    csv = Tempfile.new(["tracking_events", ".csv"])
    csv.write(<<~CSV)
      Address,Product Name,Date,Inventory Present
      "1 Bagshot Row, Hobbiton",Bree-Brewed Ale,2026-08-01,False
      "1 Bagshot Row, Hobbiton",Bree-Brewed Ale,2026-08-02,False
      "1 Bagshot Row, Hobbiton",Bree-Brewed Ale,2026-08-03,True
      "missing address",Bree-Brewed Ale,2026-08-04,False
      "1 Bagshot Row, Hobbiton",Bree-Brewed Ale,not-a-date,False
    CSV
    csv.flush

    assert_difference -> { TrackingEvent.count }, 3 do
      assert_difference -> { Alert.count }, 1 do
        result = TrackingEvents::CsvImporter.new(csv.path).call
        assert_equal 5, result[:rows_processed]
        assert_equal 3, result[:created]
        assert_equal 1, result[:alerts]
      end
    end

    alert = Alert.find_by!(product: products(:widget), store: stores(:main_street))
    assert_equal Time.zone.parse("2026-08-01"), alert.opening_tracking_event.event_time
    assert_equal Time.zone.parse("2026-08-02"), alert.confirming_tracking_event.event_time
  ensure
    csv.close!
  end

  test "aborts when tracking events already exist" do
    TrackingEvent.create!(
      product: products(:widget),
      store: stores(:main_street),
      inventory_present: true,
      event_time: Time.zone.parse("2026-01-01")
    )

    csv = Tempfile.new(["tracking_events", ".csv"])
    csv.write(<<~CSV)
      Address,Product Name,Date,Inventory Present
      "1 Bagshot Row, Hobbiton",Bree-Brewed Ale,2026-08-01,False
    CSV
    csv.flush

    assert_no_difference -> { TrackingEvent.count } do
      error = assert_raises(TrackingEvents::CsvImporter::AlreadyImportedError) do
        TrackingEvents::CsvImporter.new(csv.path).call
      end
      assert_match(/already exist/i, error.message)
    end
  ensure
    csv.close!
  end
end
