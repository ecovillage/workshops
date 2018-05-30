# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "SyncMembers" do
  before do
    @event = create(:event)
    @eventm = create(:event_with_members)
  end

  it '.initialize' do
    expect(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)

    sm = SyncMembers.new(@eventm)

    expect(sm.event).to eq(@eventm)
    expect(sm.remote_members).not_to be_empty
    expect(sm.sync_errors).to be_a(ErrorReport)
  end

  describe '.get_remote_members' do
    context 'with no remote members' do
      it 'sends a message to ErrorReport and raises an error message' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect_any_instance_of(ErrorReport).to receive(:add).with(lc, "Unable to retrieve any remote members for #{@event.code}")
        expect { @sm = SyncMembers.new(@event) }.to raise_error('NoResultsError')
      end

      it 'sends email to staff' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect {
          expect{
            SyncMembers.new(@event)
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        }.to raise_error('NoResultsError')
      end
    end

    context 'with remote members' do
      it 'returns the remote members' do
        lc = FakeLegacyConnector.new
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sm = SyncMembers.new(@eventm)

        expect(sm.remote_members).not_to be_empty
      end
    end
  end

  describe '.fix_remote_fields' do
    it 'fills in blank fields, sets Backup Participant attendance to "Not Yet Invited"' do
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(@eventm).and_return(lc.get_members_with_changed_fields(@eventm))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      SyncMembers.new(@eventm)
      member = Event.find(@eventm.id).memberships.last

      expect(member.person.updated_by).to eq('Workshops importer')
      expect(member.person.updated_at).not_to be_nil
      expect(member.updated_by).to eq('Workshops importer')
      expect(member.updated_at).not_to be_nil
      expect(member.role).to eq('Backup Participant')
      expect(member.attendance).to eq('Not Yet Invited')
    end
  end

  describe '.update_person' do
    def test_update(local_person:, fields:)
      membership = create(:membership, event: @eventm, person: local_person)
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(@eventm)
        .and_return(lc.get_members_with_person(e: @eventm,
                                               m: membership,
                                               changed_fields: fields))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      SyncMembers.new(@eventm)

      lp = Person.find(local_person.id)

      fields.each_pair do |k, v|
        expect(lp.send(k)).to eq(v)
      end
    end

    def setup_remote(event, membership, changed_fields)
      lc = FakeLegacyConnector.new
      remote_members = lc.get_members_with_person(
        e: event, m: membership, changed_fields: changed_fields
      )
      allow(lc).to receive(:get_members).with(event)
        .and_return(remote_members)
      expect(LegacyConnector).to receive(:new).and_return(lc)
    end

    context 'remote person with matching legacy_id' do
      it 'updates the local person with changed fields' do
        local_person = create(:person, lastname: 'Localperson', legacy_id: 666)
        updated_fields = { lastname: 'RemotePerson', address1: 'foo' }
        test_update(local_person: local_person, fields: updated_fields)
      end
    end

    context 'remote person without a legacy_id' do
      it 'finds local person based on email address, and updates' do
        local_person = create(:person, lastname: 'Localperson', legacy_id: nil)
        updated_fields = { lastname: 'RemotePerson' }
        test_update(local_person: local_person, fields: updated_fields)
      end
    end

    context 'without a local person' do
      it 'creates a new person record' do
        setup_remote(@eventm, nil, lastname: 'Remoteperson')

        SyncMembers.new(@eventm)

        lp = Event.find(@eventm.id).members.last
        expect(lp.lastname).to eq('Remoteperson')
      end
    end

    context 'Email & legacy_id updates' do
      context 'remote member has matching email, different legacy_id' do
        before do
          @person1 = create(:person, email: 'sam@jones.net', legacy_id: 111)
          @membership1 = create(:membership, person: @person1, event: @eventm)

          @person2 = create(:person, email: 'fred@smith.com', legacy_id: 222)
          @membership2 = create(:membership, person: @person2, event: @event)

          @lecture = create(:lecture, person: @person1, event: @eventm)
          create(:user, person: @person1, email: @person1.email)

          remote_fields = { email: 'sam@jones.net', legacy_id: 222 }
          setup_remote(@eventm, @membership1, remote_fields)
          SyncMembers.new(@eventm)
        end

        after do
          @event.memberships.destroy_all
        end

        it 'updates the legacy_id of local member with matching email' do
          membership = Membership.find(@membership1.id)
          expect(membership.person.legacy_id).to eq(222)
        end
      end

      context 'remote member has matching legacy_id, but different email' do
        before do
          @person1 = create(:person, email: 'sam@jones.net', legacy_id: 111)
          @membership1 = create(:membership, person: @person1, event: @eventm)

          @person2 = create(:person, email: 'fred@smith.com', legacy_id: 222)
          @membership2 = create(:membership, person: @person2, event: @event)

          @lecture = create(:lecture, person: @person1, event: @eventm)
          create(:user, person: @person1, email: @person1.email)

          remote_fields = { email: 'fred@smith.com', legacy_id: 111 }
          setup_remote(@eventm, @membership1, remote_fields)
          SyncMembers.new(@eventm)
        end

        after do
          @event.memberships.destroy_all
        end

        it 'updates the email address of local member with matching legacy_id' do
          membership = Membership.find(@membership1.id)
          expect(membership.person.email).to eq('fred@smith.com')
        end

        it 'consolidates event memberships into one person record' do
          expect { Person.find(@person2.id) }
            .to raise_exception(ActiveRecord::RecordNotFound)
          updated_person = Person.find(@person1.id)
          events = updated_person.memberships.collect(&:event).flatten
          expect(events).to match_array([@event, @eventm])
          expect(updated_person.legacy_id).to eq(111)
        end

        it 'consolidates lectures into one person record' do
          lecture = Lecture.find(@lecture.id)
          expect(lecture.person).to eq(@person1)
        end

        it 'moves user account to updated person record' do
          expect(User.where(person_id: @person1.id)).not_to be_nil
        end
      end

      context 'member of event does not match remote legacy_ids or emails' do
        it 'deletes that event membership' do
          @event.memberships.destroy_all
          member1 = create(:membership, event: @event)
          member2 = create(:membership, event: @event)
          setup_remote(@event, member2, firstname: 'Remotely')

          SyncMembers.new(@event)

          expect { Membership.find(member1.id) }
            .to raise_exception(ActiveRecord::RecordNotFound)
          expect(Membership.where(event: @event)).to include(member2)
        end
      end
    end
  end

  describe '.save_person' do
    context 'valid person' do
      it 'saves the Person and logs a message' do
        lc = FakeLegacyConnector.new
        fields = { firstname: 'New', lastname: 'McPerson' }
        allow(lc).to receive(:get_members).with(@eventm)
          .and_return(lc.get_members_with_person(e: @eventm,
                                                 m: nil,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        expect(Rails.logger).to receive(:info).with("\n\n" + "* Saved
          #{@eventm.code} person: New McPerson".squish + "\n")
        expect(Rails.logger).to receive(:info).with("\n\n" + "* Saved
          #{@eventm.code} membership for New McPerson".squish + "\n")

        SyncMembers.new(@eventm)

        lp = Event.find(@eventm.id).members.last
        expect(lp.name).to eq('New McPerson')
      end
    end

    context 'invalid person' do
      it 'does not save the Person, logs a message, and adds record to ErrorReport' do
        lc = FakeLegacyConnector.new
        fields = { firstname: 'New', lastname: 'McPerson', email: '' }
        allow(lc).to receive(:get_members).with(@event)
          .and_return(lc.get_members_with_person(e: @event, m: nil,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sync_errors = ErrorReport.new('SyncMembers', @event)
        expect(ErrorReport).to receive(:new).and_return(sync_errors)

        person = build(:person, email: '')
        person.valid?

        expect(Rails.logger).to receive(:error).with("\n\n" + "* Error saving
          #{@event.code} person: New McPerson,
          #{person.errors.full_messages}".squish + "\n")
        expect(sync_errors).to receive(:add).once.with(anything)
        SyncMembers.new(@event)

        expect(Event.find(@event.id).members.last).to be_nil
        @event.memberships.destroy_all
      end
    end
  end

  describe '.save_membership' do
    context 'valid membership' do
      before do
        @person = create(:person, lastname: 'Smith')
        @membership = build(:membership, person: @person, event: @event,
                                        staff_notes: 'Hi there!')
        @lc = FakeLegacyConnector.new
      end

      after do
        @event.memberships.destroy_all
      end

      it 'saves the Membership and logs a message' do
        fields = { lastname: 'Smith' }
        allow(@lc).to receive(:get_members).with(@event)
          .and_return(@lc.get_members_with_person(e: @event, m:
                                                 @membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(@lc)

        expect(Rails.logger).to receive(:info)
          .with("\n\n* Saved #{@event.code} person: #{@person.name}\n")
        expect(Rails.logger).to receive(:info)
          .with("\n\n* Saved #{@event.code} membership for #{@membership.person.name}\n")
        SyncMembers.new(@event)

        lm = Event.find(@event.id).memberships.last
        expect(lm.staff_notes).to eq('Hi there!')
      end

      it 'accepts arrival & depature dates outside of event dates' do
        arrival = @event.start_date - 2.days
        @membership.arrival_date = arrival
        departure = @event.end_date + 2.days
        @membership.departure_date = departure

        fields = { lastname: 'Claus' }
        allow(@lc).to receive(:get_members).with(@event)
          .and_return(@lc.get_members_with_person(e: @event, m:
                                                 @membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(@lc)

        SyncMembers.new(@event)

        saved_member = Event.find(@event.id).memberships.last
        expect(saved_member).not_to be_nil
        expect(saved_member.arrival_date).to eq(arrival)
        expect(saved_member.departure_date).to eq(departure)
      end
    end

    context 'invalid membership' do
      it 'does not save the Membership, logs a message,
        and adds record to ErrorReport' do
        person = create(:person, lastname: 'Smith')
        membership = build(:membership, person: person,
                                        event: @event,
                                        arrival_date: '1973-01-01')

        lc = FakeLegacyConnector.new
        fields = { lastname: 'Smith' }
        allow(lc).to receive(:get_members).with(@event)
          .and_return(lc.get_members_with_person(e: @event, m: membership,
                                                 changed_fields: fields))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        sync_errors = ErrorReport.new('SyncMembers', @event)
        expect(ErrorReport).to receive(:new).and_return(sync_errors)

        membership.valid?
        expect(Rails.logger).to receive(:error)
        expect(sync_errors).to receive(:add).with(anything)
        SyncMembers.new(@event)

        expect(Event.find(@event.id).memberships.last).to be_nil
      end
    end
  end

  describe '.update_membership' do
    context 'without a local membership' do
      it 'creates a new membership' do
        person = create(:person)
        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(@event).and_return(lc.get_members_with_new_membership(e: @event, p: person))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        SyncMembers.new(@event)

        expect(Event.find(@event.id).members.last).to eq(person)
        @event.memberships.destroy_all
      end
    end

    context 'with a local membership' do
      it 'updates the local membership' do
        membership = @eventm.memberships.last
        lc = FakeLegacyConnector.new
        allow(lc).to receive(:get_members).with(membership.event).and_return(lc.get_members_with_changed_membership(m: membership, sn: 'Hi'))
        expect(LegacyConnector).to receive(:new).and_return(lc)

        SyncMembers.new(membership.event)

        expect(Event.find(membership.event.id).memberships.last.staff_notes).to eq('Hi')
      end
    end
  end

  describe '.prune_members' do
    before do
      allow(LegacyConnector).to receive(:new).and_return(FakeLegacyConnector.new)
      @sm = SyncMembers.new(@eventm)
    end

    it 'removes local members that are not in remote memberships' do
      new_member = create(:membership, event: @eventm)
      @sm.prune_members

      expect(Event.find(@eventm.id).memberships).not_to include(new_member)
    end
  end

  describe '.check_max_participants' do
    before do
      Person.destroy_all
    end

    it 'checks whether the event has too many participants, sends report' do
      lc = FakeLegacyConnector.new
      allow(lc).to receive(:get_members).with(@event)
        .and_return(lc.exceed_max_participants(@event, 5))
      expect(LegacyConnector).to receive(:new).and_return(lc)

      sync_errors = ErrorReport.new('SyncMembers', @event)
      expect(ErrorReport).to receive(:new).and_return(sync_errors)

      # from sync_members.rb:100
      total_invited = @event.max_participants + 5
      msg = "Membership Totals:\n"
      msg += "Confirmed participants: #{total_invited}\n"
      msg += "Invited participants: 0\n"
      msg += "Undecided participants: 0\n"
      msg += "Not Yet Invited participants: 0\n"
      msg += "Declined participants: 0\n\n"
      msg += "Total invited: #{total_invited}\n"
      msg += "#{@event.code} Maximum allowed: #{@event.max_participants}\n"
      message = "#{@event.code} is overbooked!\n\n#{msg}"

      expect(sync_errors).to receive(:add).with(@event, message)
      expect(sync_errors).to receive(:send_report)
      SyncMembers.new(@event)
    end
  end
end
