# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class EventPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @event = model.nil? ? Event.new : model
  end

  def method_missing(name, *args)
    if @current_user
      if staff_at_location
        @event.template && name =~ /edit|update/
      else
        @current_user.is_admin?
      end
    end
  end

  # Include template events for staff in #all view
  class Scope < Struct.new(:current_user, :model)
    def resolve
      if current_user.is_admin? || current_user.staff?
        model.all.order(:start_date)
      else
        model.where(:template => false).order(:start_date)
      end
    end
  end

  def show?
    if @event.template
      allow_staff_and_admins
    else
      true
    end
  end

  def view_attendance_status?(status)
    if allow_orgs_and_admins
      true
    else
      ['Confirmed', 'Invited', 'Undecided'].include?(status)
    end
  end

  def view_email_addresses?
    if @current_user
      @current_user.is_member?(@event) || @current_user.is_admin? || staff_at_location
    end
  end

  # To allow the use of emails when they are not shared by the member
  def use_email_addresses?
    allow_orgs_and_admins
  end

  def show_invite_buttons?
    allow_staff_and_admins
  end

  def sync?
    if @event.end_date >= Date.today && !@event.template
      allow_staff_and_admins unless Rails.env.test?
    end
  end

  def view_details?
    view_email_addresses?
  end

  def event_staff?
    allow_staff_and_admins
  end

  private

  def staff_at_location
    @current_user.staff? && @current_user.location == @event.location
  end

  def allow_staff_and_admins
    if @current_user
      @current_user.is_admin?  || staff_at_location
    end
  end

  def allow_orgs_and_admins
    if @current_user
      @current_user.is_organizer?(@event) || @current_user.is_admin?  || staff_at_location
    end
  end

end