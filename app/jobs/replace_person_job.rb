# app/jobs/replace_person_job.rb
#
# Copyright (c) 2019 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

# Connects to legacy database to replace a person record with another one
class ReplacePersonJob < ApplicationJob
  queue_as :urgent

  rescue_from(RuntimeError) do |error|
    if error.message == 'JSON::ParserError'
      StaffMailer.notify_sysadmin(nil, error).deliver_now
    else
      retry_job wait: 1.minutes, queue: :default
    end
  end

  def perform(replace_legacy_id, replace_with_legacy_id)
    LegacyConnector.new.replace_person(replace_legacy_id, replace_with_legacy_id)
  end
end
