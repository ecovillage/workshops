# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module PersonDecorators
  extend ActiveSupport::Concern

  def name
    unless lastname.blank? || firstname.blank?
      firstname + ' ' + lastname
    else
      'N/A'
    end
  end

  def lname
    unless lastname.blank? || firstname.blank?
      lastname + ', ' + firstname
    else
      'N/A'
    end
  end

  def dear_name
    if salutation.blank?
      if academic_status == 'Professor'
        'Prof. ' + lastname
      else
        self.name
      end
    else
      salutation + ' ' + lastname
    end
  end

  def him
    self.gender == 'M' ? 'him' : 'her'
  end
  
  def affil
    affil = String.new(affiliation)
    affil << ", #{department}" unless department.blank?
    affil
  end

  def affil_with_title
    formatted_affil = affil
    if title.blank?
      formatted_affil << " — #{academic_status}" unless academic_status.blank? && academic_status != "Other"
    else
      formatted_affil << " — #{title}"
    end
    formatted_affil.html_safe
  end

  def his_her
    gender == 'M' ? 'his' : 'her'
  end

end