namespace :alerts do
  desc "Rebuild stockout alerts from tracking events already in the database"
  task backfill: :environment do
    count = Alerts::Backfill.call
    puts "Rebuilt #{count} alerts."
  end
end
