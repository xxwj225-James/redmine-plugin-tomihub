require 'net/http'
r = Net::HTTP.get(URI('http://localhost:3000/projects/testproj')).force_encoding('UTF-8')
checks = {
  'health card' => r.include?('tomihub-health'),
  'score 60' => r.include?('tomihub-score">60'),
  'risk dot quality' => r.include?('dot-quality'),
  'risk dot delivery' => r.include?('dot-delivery'),
  'issue link -> redmine path' => r.include?('href="/issues/36"'),
  'issue link NOT tomihub' => !r.match?(/issue-link[^>]*href="[^"]*tomihub_url/) && !r.include?('/issues/36?from=redmine-plugin'),
  'trend sparkline varied' => (r[/<polyline points="([^"]+)"/, 1] || '').split.count >= 4 &&
      (r[/<polyline points="([^"]+)"/, 1] || '').split.map { |pt| pt.split(',').last.to_f }.uniq.count >= 4,
  'kmap title' => r.include?('Project Knowledge Map'),
  'kmap pages meta' => r.include?('2 pages'),
  'kmap AI summary' => r.include?('kmap-ai-summary') && r.include?('Auto-seeded by redmine_connector'),
  'kmap AI team' => r.include?('1 team members'),
  'kmap AI onboarding' => r.include?('kmap-ai-steps') && r.include?('API-Reference'),
  'kmap page row links redmine wiki' => r.include?('href="/projects/testproj/wiki/API-Reference"'),
  'kmap page snippet shown' => r.include?('kmap-page-snippet') && r.include?('Endpoints are documented'),
  'no bug emoji' => !r.include?('🐛'),
}
checks.each { |k, v| puts (v ? 'PASS' : 'FAIL') + '  ' + k }
