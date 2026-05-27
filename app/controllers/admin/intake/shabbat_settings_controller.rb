module Admin
  module Intake
    class ShabbatSettingsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_admin!
      layout "admin"

      def edit
        @setting = ::Intake::AppSetting.current
      end

      def update
        @setting = ::Intake::AppSetting.current
        if @setting.update(setting_params)
          redirect_to edit_admin_intake_shabbat_settings_path, notice: "Shabbat settings updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def setting_params
        params.require(:setting).permit(:shabbat_mode_enabled, :shabbat_timezone)
      end
    end
  end
end
