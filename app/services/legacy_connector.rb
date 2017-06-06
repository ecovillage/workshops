# Copyright (c) 2016 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Connects to internal API for legacy database
class LegacyConnector
  require 'rest_client'

  def initialize
    @rest_url = Setting.Site['legacy_api']
  end

  # get a list of events within a given date range
  def list_events(from_date, to_date)
     JSON.parse(RestClient.get "#{@rest_url}/event_list",
                {params: {year1: from_date, year2: to_date}})
  end

  # get data for specific events
  def get_event_data(event_id)
    JSON.parse(RestClient.get "#{@rest_url}/event_data/#{event_id}")
  end

  # get event data for given year
  def get_event_data_for_year(year)
    JSON.parse((RestClient.get "#{@rest_url}/event_data_for_year/#{year}"))
  end

  # get membership data for an event
  def get_members(event)
    JSON.parse((RestClient.get "#{@rest_url}/members/#{event.code}"))
  end

  # get a person record data
  def get_person(legacy_id)
    JSON.parse((RestClient.get "#{@rest_url}/get_person/#{legacy_id}"))
  end

  # search legacy db for person by email
  def search_person(email)
    JSON.parse((RestClient.get "#{@rest_url}/search_person/#{email}"))
  end

  # add or update person record
  def add_person(person:, updated_by:)
    remote_person = person.attributes.merge(updated_by: updated_by)
    JSON.parse((RestClient.post "#{@rest_url}/add_person",
                                remote_person.to_json,
                                content_type: :json, accept: :json))
  end

  # add new member to event
  def add_member(membership:, event_code:, person:, updated_by:)
    remote_person = person.attributes.merge(updated_by: updated_by)
    remote_membership = membership.attributes.merge(
      workshop_id: event_code,
      person:      remote_person.as_json,
      updated_by:  updated_by
    )

    JSON.parse((RestClient.post "#{@rest_url}/add_member/#{event_code}",
                                remote_membership.to_json,
                                content_type: :json,
                                accept: :json))
  end

  # add new members to event
  def add_members(event_code:, members:, updated_by:)
    responses = []
    members.each do |member|
      responses[] = add_member(membership: member,
                               event_code: event_code,
                               legacy_id:  member.legacy_id,
                               updated_by: updated_by)
    end
  end

  # update membership & person record
  def update_member(membership)
    person = membership.person.attributes
                       .merge(updated_by: membership.updated_by)
    # add_member() adds or updates memberships
    add_member(membership: membership,
               event_code: membership.event.code,
               person: person,
               updated_by: membership.updated_by)
  end

  # update an event's members
  def update_members(event_id, members)
  end

  # get an events lectures
  def get_lectures(event_id)
    JSON.parse(RestClient.get "#{@rest_url}/event_lectures/#{event_id}")
  end

  def get_lecture(legacy_id)
    JSON.parse(RestClient.get "#{@rest_url}/get_lecture/#{legacy_id}")
  end

  # get legacy_id of a given lecture
  def get_lecture_id(lecture)
    day = lecture.start_time.strftime("%Y-%m-%d")
    lecture_hash = JSON.parse(RestClient.get "#{@rest_url}/new_lecture_id/#{lecture.event.code}/#{day}/#{lecture.id}")
    lecture_hash["legacy_id"].to_i
  end

  # add a lecture
  def add_lecture(lecture)
    event_id = lecture.event.code
    lecture.person_id = lecture.person.legacy_id
    RestClient.post "#{@rest_url}/add_lecture/#{event_id}", lecture.to_json, content_type: :json, accept: :json
    get_lecture_id(lecture)
  end

  def delete_lecture(lecture_id)
    JSON.parse(RestClient.get "#{@rest_url}/delete_lecture/#{lecture_id}")
  end

  def check_rsvp(otp)
    JSON.parse(RestClient.get "#{@rest_url}/check_rsvp/#{otp}")
  end
end
