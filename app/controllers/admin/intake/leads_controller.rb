module Admin
  module Intake
    class LeadsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_admin!
      layout "admin"

      before_action :set_lead, only: [ :show, :edit, :update ]

      def index
        @leads = ::Intake::Lead.order(created_at: :desc)
        @leads = @leads.by_status(params[:status]) if params[:status].present?
        @leads = @leads.search(params[:q]) if params[:q].present?
      end

      def show
      end

      def edit
      end

      def update
        if @lead.update(lead_params)
          redirect_to admin_intake_lead_path(@lead), notice: "Lead updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def set_lead
        @lead = ::Intake::Lead.find(params[:id])
      end

      def lead_params
        params.require(:lead).permit(
          :first_name, :last_name, :email, :phone, :age, :gender, :seeking_gender,
          :location_city, :location_country, :religiosity_level, :relationship_goal,
          :occupation, :about_me, :what_looking_for, :deal_breakers,
          :source, :status, :admin_notes
        )
      end
    end
  end
end
