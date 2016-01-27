# Copyright (c) 2016 Brent Kearney
#
# This file is part of Workshops.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class LegacyConnector
  require 'rest_client'
    
  def initialize
    @rest_url = Global.config.legacy_api
  end
  
  # get a list of events within a given date range
  def list_events(from_date, to_date)
     JSON.parse(RestClient.get "#{@rest_url}/event_list", {:params => {'year1' => from_date, 'year2' => to_date}})
  end

  # get data for specific events
  def get_event_data(event_id)
    JSON.parse(RestClient.get "#{@rest_url}/event_data/#{event_id}")
  end
  
  # get event data for given year
  def get_event_data_for_year(year)
    JSON.parse(RestClient.get "#{@rest_url}/event_data_for_year/#{year}")
  end
  
  # get membership data for an event
  def get_members(event_id)
    JSON.parse(RestClient.get "#{@rest_url}/members/#{event_id}")
  end
  
  # get a person record data
  def get_person(legacy_id)
    JSON.parse(RestClient.get "#{@rest_url}/get_person/#{legacy_id}")
  end
  
  # search legacy db for person by email
  def search_person(email)
    JSON.parse(RestClient.get "#{@rest_url}/search_person/#{email}")
  end
  
  # update an event's members
  def update_members(event_id, members)
  end
  
  # add new person record
  def add_person(person)
    email = person["email"]
    RestClient.post "#{@rest_url}/add_person", person.to_json, :content_type => :json, :accept => :json
    # Return the legacy_id for the new remote person record
    new_person = search_person(email)
    new_person["legacy_id"]
  end
  
  # add new member to event
  def add_member(membership, event_id, legacy_id, updated_by)    
    remote_membership = membership.attributes.merge('workshop_id' => "#{event_id}", 'person_id' => "#{legacy_id}", 'updated_by' => "#{updated_by}")
    RestClient.post "#{@rest_url}/add_member/#{event_id}", remote_membership.to_json, :content_type => :json, :accept => :json    
  end

  # add new members to event
  def add_members(event_id, members)
    RestClient.post "#{@rest_url}/add_members/#{event_id}", members.to_json, :content_type => :json, :accept => :json
  end

  # update membership & person record
  def update_member(membership, person, event_id, legacy_id, updated_by)
    add_member(membership, event_id, legacy_id, updated_by) # add_member updates existing memberships
    remote_person = person.attributes.merge('updated_by' => "#{updated_by}")
    remote_person.delete("legacy_id")
    RestClient.post "#{@rest_url}/update_person/#{legacy_id}", remote_person.to_json, :content_type => :json, :accept => :json
  end

  # import memberships for given event
  def import_members(event_id)
  end

  # get an events lectures
  def get_lectures(event_id)
    JSON.parse(RestClient.get "#{@rest_url}/event_lectures/#{event_id}")
  end

  def get_legacy_lecture(legacy_id)
    JSON.parse(RestClient.get "#{@rest_url}/legacy_lecture/#{legacy_id}")
  end

  def get_new_lecture_id(lecture)
    day = lecture.start_time.strftime("%Y-%m-%d")
    JSON.parse(RestClient.get "#{@rest_url}/new_lecture_id/#{lecture.event.code}/#{day}/#{lecture.id}")
  end

  # add a lecture
  def add_lecture(lecture)
    event_id = lecture.event.code
    lecture.person_id = lecture.person.legacy_id
    RestClient.post "#{@rest_url}/add_lecture/#{event_id}", lecture.to_json, :content_type => :json, :accept => :json
    new_lecture = get_new_lecture_id(lecture)
    new_lecture['legacy_id']
  end

  def delete_lecture(lecture_id)
    RestClient.get "#{@rest_url}/delete_lecture/#{lecture_id}"
  end

  # send a report of lectures and video filenames for given event
  def send_lectures_report(event_id)
    RestClient.post "#{@rest_url}/send_lectures_report/#{event_id}", 1, :content_type => :json, :accept => :json
  end
  
end