# TomiHub AI Co-pilot for Redmine
# ==============================================================
# Free tier: project health badge + top risks (read-only summary
# pulled from a self-hosted TomiHub instance on the same LAN).
# Full analysis lives in TomiHub UI — the plugin is the hook,
# TomiHub is the product (wedge strategy, docs/redmine-plugin-design.md).
#
# MIT License — see LICENSE.
# ==============================================================
require 'redmine'

Redmine::Plugin.register :redmine_tomihub do
  name 'TomiHub AI Co-pilot'
  author 'TomatoVector'
  description 'AI-powered project health badge and risk alerts, powered by TomiHub AI-Brain. Your Redmine stays unchanged — this plugin is a read-only window into the analysis.'
  version '0.1.0'
  url 'https://tomatovector.com'
  author_url 'https://tomatovector.com'

  settings default: { 'tomihub_url' => '', 'api_key' => '', 'redmine_api_key' => '' },
           partial: 'settings/redmine_tomihub'

  # Admin-only settings page (plugin configuration)
  menu :admin_menu, :redmine_tomihub_settings,
       { controller: 'tomihub_settings', action: 'show' },
       caption: 'TomiHub', if: proc { User.current.admin? }
end

# Hook the health badge into the project overview page.
# require_relative — Redmine 7 (Zeitwerk) does not expose plugin lib/ to
# require_dependency at plugin-registration time.
require_relative 'lib/redmine_tomihub/hooks'
require_relative 'lib/redmine_tomihub/client'
