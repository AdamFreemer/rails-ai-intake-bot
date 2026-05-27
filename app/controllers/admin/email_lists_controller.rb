module Admin
  class EmailListsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    layout "admin"

    def index
    end
  end
end
