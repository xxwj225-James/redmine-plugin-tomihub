# frozen_string_literal: true

# Minimal TomiHub REST client — zero gem dependencies (net/http only).
# All AI analysis happens on the TomiHub side; this client only pulls
# results and triggers sync.
module RedmineTomihub
  class Client
    TIMEOUT = 10 # seconds

    class Error < StandardError; end
    class Unauthorized < Error; end
    class LicenseRequired < Error; end

    def initialize(base_url, api_key)
      @base_url = base_url.to_s.chomp('/')
      @api_key = api_key.to_s
    end

    # GET /api/v1/license/status — connection test + license state
    def license_status
      get('/api/v1/license/status')
    end

    # GET /api/v1/ai/redmine/project-summary?redmine_id=N&lang=xx
    def project_summary(redmine_id, lang = nil)
      params = { redmine_id: redmine_id }
      params[:lang] = lang if lang.present?
      get('/api/v1/ai/redmine/project-summary', params)
    end

    # GET /api/v1/ai/redmine/knowledge-map?redmine_id=N
    def knowledge_map(redmine_id)
      get('/api/v1/ai/redmine/knowledge-map', redmine_id: redmine_id)
    end

    # POST /api/v1/redmine/sync — trigger mirror sync (async on TomiHub side)
    def trigger_sync(redmine_url:, redmine_api_key:, project_keys:, full: false)
      post('/api/v1/redmine/sync', {
        redmine_url: redmine_url,
        redmine_api_key: redmine_api_key,
        project_keys: project_keys,
        full: full,
      })
    end

    private

    def get(path, params = {})
      uri = build_uri(path, params)
      req = Net::HTTP::Get.new(uri)
      perform(uri, req)
    end

    def post(path, body)
      uri = URI.join(@base_url + '/', path.sub(%r{\A/}, ''))
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = JSON.generate(body)
      perform(uri, req)
    end

    def build_uri(path, params)
      query = URI.encode_www_form(params.reject { |_, v| v.nil? || v == '' })
      uri = URI.join(@base_url + '/', path.sub(%r{\A/}, ''))
      uri.query = query unless query.empty?
      uri
    end

    def perform(uri, req)
      req['X-Api-Key'] = @api_key
      req['Accept'] = 'application/json'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      resp = http.request(req)
      body = resp.body.to_s

      case resp.code.to_i
      when 200..299
        parse_json(body)
      when 401
        raise Unauthorized, body
      when 403
        raise LicenseRequired, body
      else
        raise Error, "TomiHub HTTP #{resp.code}: #{body[0, 200]}"
      end
    rescue JSON::ParserError
      {}
    end

    def parse_json(body)
      return {} if body.nil? || body.empty?
      JSON.parse(body)
    end
  end
end
