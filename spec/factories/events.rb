# spec/factories/events.rb
require 'faker'

random_code = rand(10..17).to_s + 'w50' + rand(10..99).to_s

FactoryGirl.define do
  sequence(:code) { |n| DateTime.now.strftime("%y") + 'w5' + n.to_s.rjust(3, '0') }
  sequence(:start_date, 1) { |n| Date.today.advance(weeks: n).beginning_of_week(:sunday) }
  sequence(:end_date, 1) { |n| Date.today.advance(weeks: n, days: 5).beginning_of_week(:friday) }

  factory :event do |f|
    f.code
    f.name { Faker::Lorem.sentence(4) }
    f.short_name { Faker::Lorem.sentence(1) }
    f.booking_code 'Booking'
    f.door_code 1234
    f.start_date
    f.end_date
    f.event_type Global.event.types.first
    f.max_participants 42
    f.location Global.location.first
    f.time_zone 'Eastern Time (US & Canada)'
    f.description { Faker::Lorem.sentence(6) }
    f.updated_by 'FactoryGirl'
    f.template false

    factory :event_with_roles do
      after(:create) do |event|
        Membership::ROLES.shuffle.each do |role|
          person = create(:person)
          create(:membership, role: role, person: person, event: event)
        end
      end
    end



  end
end

