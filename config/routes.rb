# TomiHub plugin routes — settings page + ajax actions
RedmineApp::Application.routes.draw do
  get 'tomihub_settings', to: 'tomihub_settings#show', as: 'tomihub_settings'
  post 'tomihub_settings', to: 'tomihub_settings#save'
  post 'tomihub_settings/test_connection', to: 'tomihub_settings#test_connection'
  post 'tomihub_settings/trigger_sync', to: 'tomihub_settings#trigger_sync'
end
