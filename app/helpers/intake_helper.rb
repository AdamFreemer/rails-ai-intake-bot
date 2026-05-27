module IntakeHelper
  STATUS_BADGE_CLASSES = {
    "active"    => "bg-yellow-100 text-yellow-800",
    "completed" => "bg-green-100 text-green-800",
    "abandoned" => "bg-gray-100 text-gray-500"
  }.freeze

  MODE_PILL_CLASSES = {
    "ai"     => "bg-pk/10 text-pk",
    "human"  => "bg-blue-100 text-blue-800",
    "paused" => "bg-gray-100 text-gray-500"
  }.freeze

  LEAD_STATUS_CLASSES = {
    "new"          => "bg-yellow-100 text-yellow-800",
    "reviewed"     => "bg-blue-100 text-blue-800",
    "accepted"     => "bg-green-100 text-green-800",
    "declined"     => "bg-gray-100 text-gray-500",
    "vip_prospect" => "bg-pink-100 text-pink-800"
  }.freeze

  def intake_status_badge(status)
    classes = STATUS_BADGE_CLASSES[status.to_s] || "bg-gray-100 text-gray-500"
    content_tag :span, status.to_s.titleize,
                class: "inline-block px-2 py-0.5 rounded-full text-[0.65rem] font-medium #{classes}"
  end

  def intake_mode_pill(mode)
    classes = MODE_PILL_CLASSES[mode.to_s] || "bg-gray-100 text-gray-500"
    content_tag :span, mode.to_s.upcase,
                class: "inline-block px-2 py-0.5 rounded-full text-[0.6rem] font-semibold tracking-wider #{classes}"
  end

  def lead_status_badge(status)
    classes = LEAD_STATUS_CLASSES[status.to_s] || "bg-gray-100 text-gray-500"
    content_tag :span, status.to_s.titleize,
                class: "inline-block px-2 py-0.5 rounded-full text-[0.65rem] font-medium #{classes}"
  end

  # +15551234567 -> +1 (555) ***-4567
  def mask_phone(phone)
    return phone if phone.blank?
    digits = phone.gsub(/\D/, "")
    return phone if digits.length < 7
    "+#{digits[0]} (#{digits[1..3]}) ***-#{digits[-4..]}"
  end

  # Maps the SERVICES intake answer to a colored priority pill so the admin team can
  # triage at a glance. Matchmaking = paid headline service → highest priority;
  # database = lowest (just-in-case lead).
  def services_priority_pill(services)
    return nil if services.blank?
    s = services.to_s.downcase

    label, classes =
      if s.include?("matchmaking")
        [ "Matchmaking · High Priority", "bg-pk text-white" ]
      elsif s.include?("coaching")
        [ "Coaching · Mid Priority",     "bg-yellow-200 text-yellow-900" ]
      elsif s.include?("database")
        [ "Database",                    "bg-gray-200 text-gray-700" ]
      else
        [ services.to_s.titleize,        "bg-gray-100 text-gray-600" ]
      end

    content_tag :span, label,
                class: "inline-block px-2 py-0.5 rounded-full text-[0.6rem] font-semibold uppercase tracking-wider #{classes}"
  end

  # Renders a `<th>` whose label is a link that toggles sort direction for the
  # given column. Preserves any existing query params (search, filters) so the
  # sort plays nicely with the filter form. Targeted at the surrounding
  # Turbo Frame so only the table re-renders.
  #
  #   sortable_header(:phone, "Phone", frame: "intake_conversations_results")
  def sortable_header(column, label, frame: nil)
    column = column.to_s
    current_sort = params[:sort].to_s
    current_dir  = params[:dir].to_s
    is_active    = current_sort == column
    next_dir     = (is_active && current_dir == "asc") ? "desc" : "asc"

    href_params = request.query_parameters.merge(sort: column, dir: next_dir)
    href = "#{request.path}?#{href_params.to_query}"

    arrow = sort_arrow(is_active ? current_dir : nil)
    link_classes = "flex items-center gap-1 hover:text-gray-700 no-underline"
    link_classes += " text-gray-900" if is_active

    link_options = { class: link_classes }
    link_options[:data] = { turbo_frame: frame } if frame

    content_tag(:th, class: "text-left px-6 py-3 select-none") do
      link_to(href, **link_options) { safe_join([ label, arrow ]) }
    end
  end

  def sort_arrow(direction)
    case direction
    when "asc"
      content_tag(:svg, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
                  class: "w-3 h-3 text-pk", "stroke-width": "2.5",
                  "stroke-linecap": "round", "stroke-linejoin": "round") do
        tag.polyline(points: "18 15 12 9 6 15")
      end
    when "desc"
      content_tag(:svg, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
                  class: "w-3 h-3 text-pk", "stroke-width": "2.5",
                  "stroke-linecap": "round", "stroke-linejoin": "round") do
        tag.polyline(points: "6 9 12 15 18 9")
      end
    else
      # Faint dual-arrow indicator on idle columns so they hint at clickability
      content_tag(:svg, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
                  class: "w-3 h-3 text-gray-300", "stroke-width": "2",
                  "stroke-linecap": "round", "stroke-linejoin": "round") do
        safe_join([
          tag.polyline(points: "18 11 12 5 6 11"),
          tag.polyline(points: "18 13 12 19 6 13")
        ])
      end
    end
  end
end
