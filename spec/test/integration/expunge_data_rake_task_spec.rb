require 'rake'
require 'rails_helper'

RSpec.describe "rake expunge_data" do

  before do
    Twentyfiveten::Application.load_tasks
    Rake::Task.define_task(:environment)
  end

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
  end

  context "a completed challenge" do

    before do
      DatabaseCleaner.clean
      Timecop.freeze(Time.local(2020, 1, 1, 12, 0, 0))
      c = Challenge.create!(challenge_prompt: "Foo", administrator: Administrator.new)
      p = Participant.create!(challenge_id: c.id, consent: true)
      p.create_proposed_solution!(challenge_id: c.id, narrative: "a", first_step: "b")
      c.schedule_votes!
    end

    after { Timecop.return }

    it "should not delete within 30 days" do
      Timecop.freeze(29.days.from_now) do
        run_rake_task("expunge_data")

        expect(Challenge.count).to eq(1)
        expect(Participant.count).to eq(1)
        expect(ProposedSolution.count).to eq(1)
        expect(Vote.count).to eq(5)
      end
    end

    it "should delete 30 or older" do
      Timecop.freeze(31.days.from_now) do
        run_rake_task("expunge_data")

        expect(Challenge.count).to eq(0)
        expect(Participant.count).to eq(0)
        expect(ProposedSolution.count).to eq(0)
        expect(Vote.count).to eq(0)
      end
    end
  end

end
