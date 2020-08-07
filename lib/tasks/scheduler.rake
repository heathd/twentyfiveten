desc "This task is called by the Heroku scheduler add-on"
task :expunge_data => :environment do
  puts "Expunging old data..."
  puts "done."
end
