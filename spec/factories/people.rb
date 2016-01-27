# spec/factories/people.rb
require 'faker'

FactoryGirl.define do
  sequence(:firstname) { |n| "Person-#{n}" }
  sequence(:email) { |n| "person-#{n}@" + Faker::Internet.domain_name }

  factory :person do |f|
    lastname = Faker::Name.last_name
    f.salutation Global.person.salutations.sample
    f.firstname
    f.lastname { lastname }
    f.gender ['M', 'F'].sample
    f.email
    f.url { Faker::Internet.url }
    f.phone { Faker::PhoneNumber.phone_number }
    f.affiliation { Faker::Company.name }
    f.department { Faker::Commerce.department }
    f.academic_status Global.person.academic_status.sample
    f.updated_by 'FactoryGirl'
  end
end