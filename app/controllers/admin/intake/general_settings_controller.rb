module Admin
  module Intake
    class GeneralSettingsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_admin!
      layout "admin"

      def edit
        @setting = ::Intake::AppSetting.current
      end

      def update
        @setting = ::Intake::AppSetting.current
        if @setting.update(setting_params)
          redirect_to edit_admin_intake_general_settings_path, notice: "General settings updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def setting_params
        params.require(:setting).permit(:global_mode, :paused_auto_reply)
      end
    end
  end
end
