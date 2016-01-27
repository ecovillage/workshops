# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module MembershipsHelper
  def show_roles(f)
    f.select :role, Membership::ROLES, {}, { required: 'true', autofocus: 'true', class: 'form-control' }
  end

  def show_invite_button(member)
    column = ''
    if @pending_invites && policy(@event).show_invite_buttons?
      column = '<td class="invite">'
      if member.is_org? && !member.sent_invitation
        column << "#{link_to 'Invite', event_memberships_invite_path(@event, member), method: :put, data: { confirm: %Q(This will send an email to #{member.person.name}, inviting #{member.person.him} to set a password and login. Proceed?) }, class: 'btn btn-primary btn-xs invite-btn', id: %Q(org-#{member.id})}"
      end
      column << '</td>'
    end
    column.html_safe
  end

  def show_email(member)
    column = ''
    if policy(@event).view_email_addresses?
      if member.shares_email?
        column = '<td class="hidden-md hidden-lg rowlink-skip" align="middle">' +
          mail_to(member.person.email, '<span class="glyphicon glyphicon-envelope"></span>'.html_safe, :title => "#{member.person.email}", subject: "[#{@event.code}] ") +
          '</td><td class="hidden-xs hidden-sm rowlink-skip">' +
          mail_to(member.person.email, member.person.email, subject: "[#{@event.code}] ") +
          '</td>'
      else
        if policy(@event).use_email_addresses?
          column = '<td class="hidden-md hidden-lg rowlink-skip" align="middle">' +
            mail_to(member.person.email, '<span class="glyphicon glyphicon-lock"></span>'.html_safe, :title => "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td><td class="hidden-xs hidden-sm rowlink-skip">' +
            mail_to(member.person.email, '[not shared]', :title => "E-mail not shared with other members", subject: "[#{@event.code}] ") +
            '</td>'
        else
          column = '<td class="hidden-md hidden-lg rowlink-skip" align="middle">' +
            '<a title="E-mail not shared" class="glyphicon glyphicon-lock"></a></td>' +
            '<td class="hidden-xs hidden-sm rowlink-skip">[not shared]</td>'
        end
      end
    end
    column.html_safe
  end

end