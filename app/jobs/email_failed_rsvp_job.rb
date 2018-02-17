# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Initiates StaffMailer to confirm RSVPs
class EmailFailedRsvpJob < ActiveJob::Base
  queue_as :urgent

  def perform(membership_id, params)
    membership = Membership.find_by_id(membership_id)
    StaffMailer.rsvp_failed(membership, params: params).deliver_now
  end
end
