# frozen_string_literal: true

module RedmineTomihub
  class Hooks < Redmine::Hook::ViewListener
    # Health badge on the project overview page (free tier).
    # Redmine 7 hook name — older versions used view_projects_show_top.
    render_on :view_projects_show_left, partial: 'projects/tomihub_health'
  end
end
