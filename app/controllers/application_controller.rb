class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Not authorized."
    end
  end

  def require_super_admin!
    unless current_user&.super_admin?
      redirect_to root_path, alert: "Super admin access required."
    end
  end
end
