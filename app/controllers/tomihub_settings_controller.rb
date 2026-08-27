# TomiHub plugin settings — admin only (menu gated in init.rb).
# Stores: tomihub_url, api_key (plugin read-only key), redmine_api_key
# (used by TomiHub-side mirror sync to pull THIS Redmine via REST).
class TomihubSettingsController < ApplicationController
  before_action :require_admin, except: [:guide]

  def show
    @settings = Setting.plugin_redmine_tomihub
  end

  # PUBLIC guide page — shown to users whose TomiHub is not configured
  # yet (health card CTA points here instead of a dead TomiHub URL).
  # Static content: what TomiHub is, how to install it, and where an
  # admin fills in the connection settings.
  def guide
    @settings = Setting.plugin_redmine_tomihub
    @configured = @settings['tomihub_url'].present? && @settings['api_key'].present?
    @is_admin = User.current.admin?
  end

  def save
    Setting.plugin_redmine_tomihub = {
      'tomihub_url' => params[:tomihub_url].to_s.strip,
      'api_key' => params[:api_key].to_s.strip,
      'redmine_api_key' => params[:redmine_api_key].to_s.strip,
    }
    flash[:notice] = l(:tomihub_settings_saved)
    redirect_to action: 'show'
  end

  def test_connection
    client = build_client
    data = client.license_status
    has_license = data.dig('data', 'hasLicense')
    render json: { ok: true, hasLicense: has_license == true }
  rescue RedmineTomihub::Client::Unauthorized
    render json: { ok: false, error: l(:tomihub_error_unauthorized) }, status: 401
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: 502
  end

  def trigger_sync
    client = build_client
    keys = params[:project_keys].to_s.split(',').map(&:strip).reject(&:empty?)
    data = client.trigger_sync(
      redmine_url: redmine_api_base_url,
      redmine_api_key: Setting.plugin_redmine_tomihub['redmine_api_key'],
      project_keys: keys,
    )
    render json: { ok: true, status: data.dig('data', 'status') || 'queued' }
  rescue RedmineTomihub::Client::Unauthorized
    render json: { ok: false, error: l(:tomihub_error_unauthorized) }, status: 401
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: 502
  end

  private

  def build_client
    url = Setting.plugin_redmine_tomihub['tomihub_url']
    key = Setting.plugin_redmine_tomihub['api_key']
    raise RedmineTomihub::Client::Error, l(:tomihub_error_not_configured) if url.blank? || key.blank?
    RedmineTomihub::Client.new(url, key)
  end

  # The TomiHub-side connector pulls THIS Redmine over REST. Give it the
  # base URL a same-LAN TomiHub instance can reach. Defaults to the
  # request's host:port, which is correct for same-LAN deployments.
  def redmine_api_base_url
    Setting.plugin_redmine_tomihub['redmine_url']&.presence ||
      "#{request.protocol}#{request.host_with_port}"
  end
end
