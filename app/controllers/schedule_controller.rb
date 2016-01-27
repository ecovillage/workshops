# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

class ScheduleController < ApplicationController
  before_action :set_schedule, only: [:show, :update, :destroy]
  before_action :set_event, :set_attendance, :set_time_zone

  before_filter :authenticate_user!, :except => [:index]
  after_filter :flash_notice, only: [:create, :update, :edit]

  # GET /events/:event_id/schedule
  # GET /events/:event_id/schedule.json
  def index
    @schedules = DefaultSchedule.new(@event, current_user).schedules
    @schedule_policy = Schedule.new(event: @event)
    if request.format.html? && @schedules.empty? && !current_user
      redirect_to sign_in_path
    end
  end

  # GET /events/:event_id/schedule/send_video_filenames
  def send_video_filenames
    if Rails.env.production?
      lc = LegacyConnector.new
      lc.send_lectures_report(@event.code)
    end
    redirect_to event_schedule_index_path(@event), notice: "Video filenames were sent to #{@event.location} for #{@event.code}"
  end

  # POST /events/:event_id/schedule/schedule_publish
  def publish_schedule
    if @event.update(publish_schedule: params[:publish_schedule])
      respond_to do |format|
        format.js
      end
    end
  end

  # GET /schedule/1
  # GET /schedule/1.json
  def show
  end

  # GET /schedule/new
  def new
    authorize Schedule.new(event: @event)
    @day = params[:day].to_date
    new_params = { new_item: true, event_id: @event.id, start_time: @day.to_time, updated_by: current_user.name }
    @schedule = ScheduleItem.new(new_params).schedule
    @members = @event.members

    @form_action = 'create'
  end

  # GET /schedule/1/edit
  def edit
    @schedule = ScheduleItem.get(params[:id])
    authorize @schedule
    @day = @schedule.day
    @form_action = 'update'
    session[:return_to] = request.referer
  end

  # POST /events/:event_id/schedule
  # POST /events/:event_id/schedule.json
  def create
    @schedule = ScheduleItem.new(schedule_params.merge(:updated_by => current_user.name)).schedule
    authorize @schedule

    respond_to do |format|
      if @schedule.valid? && @schedule.save
        day = @schedule.start_time.to_date
        name = @schedule.name
        format.html { redirect_to event_schedule_day_path(@event, day), notice: "\"#{name}\" was successfully scheduled." }
        format.json { render :show, status: :created, location: @schedule }
      else
        @day = params[:day].to_time
        @form_action = 'create'
        format.html { render :new }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event/:event_id/schedule/1
  # PATCH/PUT /event/:event_id/schedule/1.json
  def update
    authorize @schedule
    @original_item = @schedule.dup if params[:change_similar]
    merged_params = ScheduleItem.update(@schedule, schedule_params.merge(:updated_by => current_user.name))
    @day = @schedule.start_time.to_date

    if session[:return_to]
      from_where_we_came = session[:return_to]
    else
      from_where_we_came = event_schedule_index_path(@event)
    end

    respond_to do |format|
      if @schedule.update(merged_params)
        ScheduleItem.update_others(@original_item, merged_params) unless @original_item.nil?
        format.html { redirect_to from_where_we_came, notice: "\"#{@schedule.name}\" was successfully updated." }
        format.json { render :show, status: :ok, location: @schedule }
      else
        unless @schedule.lecture_id.nil?
          @schedule.name = @schedule.lecture.title
          @schedule.description = @schedule.lecture.abstract
        end
        @form_action = 'update'
        format.html { render :edit }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schedule/1
  # DELETE /schedule/1.json
  def destroy
    authorize @schedule
    if @schedule.lecture.blank?
      @schedule.destroy
    else
      @schedule.lecture.destroy # dependent: :destroy
    end

    respond_to do |format|
      format.html { redirect_to event_schedule_index_path(@event), notice: 'Schedule item was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  def schedule_params
    params.require(:schedule).permit(:id, :event_id, :start_time, :end_time, :name, :description, :location, :day, lecture_attributes: [ :person_id, :id, :keywords, :do_not_publish ] )
  end

  def flash_notice
    unless @schedule.flash_notice.blank?
      @schedule.flash_notice.each {|k, v| flash[k] = "<strong>#{k.capitalize}:</strong> #{v}" }
    end
  end

end