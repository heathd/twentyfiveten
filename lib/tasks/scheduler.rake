desc "This task is called by the Heroku scheduler add-on"
task :expunge_data => :environment do
  Rails.logger = ActiveSupport::BroadcastLogger.new(Rails.logger, Logger.new($stderr))

  threshold = 30.days.ago
  Rails.logger.info "[expunge_data] Expunging data created on or before #{threshold}..."

  [Vote, ProposedSolution, Participant, Challenge].each do |klass|
    n = klass.where("created_at <= ?", threshold).delete_all
    Rails.logger.info "[expunge_data] Deleted #{n} #{klass} records"
  end
  Rails.logger.info "[expunge_data] done."
end
