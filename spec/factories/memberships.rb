FactoryGirl.define do
  require 'faker'

  factory :membership do |f|
    association :person, factory: :person
    association :event, factory: :event

    f.role 'Participant'
    f.attendance 'Confirmed'
    f.replied_at Faker::Date.backward(14)
    f.updated_by 'FactoryGirl'
  end

end