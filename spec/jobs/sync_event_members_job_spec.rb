# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

# Thanks Chuck! https://medium.com/@chuckjhardy/testing-rails-activejob-with-rspec-5c3de1a64b66
RSpec.describe SyncEventMembersJob, type: :job do
  include ActiveJob::TestHelper

  before do
    @event = FactoryGirl.create(:event, code: '16w5666')
    @person = FactoryGirl.create(:person)
    @membership = FactoryGirl.create(:membership, person: @person, event: @event)
  end

  subject(:job) { described_class.perform_later(@event) }

  it 'queues the job' do
    expect { job }
        .to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'is in urgent queue' do
    expect(SyncEventMembersJob.new.queue_name).to eq('urgent')
  end

  it 'executes perform' do
    expect {
      expect(SyncMembers.new(@event)).to receive(:run)
      perform_enqueued_jobs { job }
    }.to raise_error(RuntimeError) # Error because 16w5666 has no members
  end

  it 'handles no results error' do
    allow(SyncMembers).to receive(:new).and_raise('NoResultsError')

    perform_enqueued_jobs do
      expect_any_instance_of(SyncEventMembersJob).to receive(:retry_job).with(wait: 5.minutes, queue: :default)
      job
    end
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

end