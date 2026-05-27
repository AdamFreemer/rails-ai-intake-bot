module AdminNavHelper
  # True if the current request path starts with any of the given prefixes.
  # Used to highlight the active top-nav item.
  def admin_nav_active?(*path_prefixes)
    path_prefixes.flatten.any? { |p| request.path == p || request.path.start_with?("#{p}/") }
  end

  # Tailwind classes for a top-level nav item — pink-accent underline + darker
  # text when active, muted gray otherwise.
  def admin_nav_link_class(active)
    base = "no-underline transition-colors pb-0.5 border-b-2"
    if active
      "#{base} text-gray-900 border-pk"
    else
      "#{base} text-gray-500 hover:text-gray-900 border-transparent"
    end
  end
end
