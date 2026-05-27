module Admin
  module Intake
    class QuietHoursSettingsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_admin!
      layout "admin"

      def edit
        @setting = ::Intake::AppSetting.current
      end

      def update
        @setting = ::Intake::AppSetting.current
        if @setting.update(setting_params)
          redirect_to edit_admin_intake_quiet_hours_settings_path, notice: "Quiet Hours settings updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def setting_params
        params.require(:setting).permit(:quiet_hours_enabled, :quiet_hours_timezone)
      end
    end
  end
end
