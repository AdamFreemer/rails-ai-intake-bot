module Admin
  class UserSettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    layout "admin"

    def edit
    end
  end
end
