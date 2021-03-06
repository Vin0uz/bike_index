module Organized
  class ImpoundRecordsController < Organized::BaseController
    include SortableTable
    before_action :set_period, only: [:index]
    before_action :find_impound_record, except: [:index]

    def index
      @page = params[:page] || 1
      @per_page = params[:per_page] || 25
      @interpreted_params = Bike.searchable_interpreted_params(permitted_org_bike_search_params, ip: forwarded_ip_address)
      @selected_query_items_options = Bike.selected_query_items_options(@interpreted_params)

      @impound_records = available_impound_records.reorder("impound_records.#{sort_column} #{sort_direction}")
        .page(@page).per(@per_page)
        .includes(:user, :bike, :location)
    end

    def show
      @approved_impound_claim = @impound_record.impound_claims.approved.first
    end

    def update
      @impound_record_update = @impound_record.impound_record_updates.new(permitted_parameters)
      is_valid_kind = @impound_record.update_kinds.include?(@impound_record_update.kind)
      if @impound_record.update_kinds.include?(@impound_record_update.kind) && @impound_record_update.save
        flash[:success] = "Recorded #{@impound_record_update.kind_humanized}"
        redirect_to organization_impound_record_path(@impound_record.display_id, organization_id: current_organization.to_param)
      else
        flash[:error] = if is_valid_kind
          @impound_record_update.errors.full_messages
        else
          "Sorry, you can't update this impound record with #{@impound_record_update.kind_humanized}"
        end
        render :show
      end
    end

    helper_method :available_impound_records, :available_statuses

    private

    def impound_records
      current_organization.impound_records
    end

    def sortable_columns
      %w[display_id created_at updated_at user_id resolved_at location_id]
    end

    def available_statuses
      %w[current resolved all] + (ImpoundRecord.statuses - ["current"]) # current ordered the way we want to display
    end

    def bike_search_params_present?
      @interpreted_params.except(:stolenness).values.any? || @selected_query_items_options.any? || params[:search_email].present?
    end

    def available_impound_records
      return @available_impound_records if defined?(@available_impound_records)
      if params[:search_status] == "all"
        @search_status = "all"
        a_impound_records = impound_records
      else
        @search_status = available_statuses.include?(params[:search_status]) ? params[:search_status] : available_statuses.first
        a_impound_records = if ImpoundRecord.statuses.include?(@search_status)
          impound_records.where(status: @search_status)
        else
          impound_records.send(@search_status)
        end
      end

      if bike_search_params_present?
        bikes = a_impound_records.bikes.search(@interpreted_params)
        bikes = bikes.organized_email_search(params[:search_email]) if params[:search_email].present?
        a_impound_records = a_impound_records.where(bike_id: bikes.pluck(:id))
      elsif params[:search_bike_id].present?
        a_impound_records = a_impound_records.where(bike_id: params[:search_bike_id])
      end

      @available_impound_records = a_impound_records.where(created_at: @time_range)
    end

    def find_impound_record
      # NOTE: Uses display_id, not normal id, unless id starts with pkey-
      @impound_record = if params[:id].start_with?("pkey-")
        impound_records.find_by_id(params[:id].gsub("pkey-", ""))
      else
        impound_records.find_by_display_id(params[:id])
      end
      raise ActiveRecord::RecordNotFound unless @impound_record.present?
    end

    def permitted_parameters
      params.require(:impound_record_update)
        .permit(:kind, :notes, :location_id, :transfer_email)
        .merge(user_id: current_user.id)
    end
  end
end
