class User < ApplicationRecord
  # Email whitelist for super-admin privileges. Super admins can access the
  # Chatbot Configuration page; regular admins can do everything else.
  SUPER_ADMIN_EMAILS = %w[admin@example.com].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  def super_admin?
    SUPER_ADMIN_EMAILS.include?(email)
  end
end
