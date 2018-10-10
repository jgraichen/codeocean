set :application, 'code_ocean'
set :config_example_suffix, '.example'
set :default_env, 'PATH' => '/usr/java/jdk1.8.0_40/bin:$PATH'
set :deploy_to, '/var/www/app'
set :keep_releases, 3
set :linked_dirs, %w(log public/uploads tmp/cache tmp/files tmp/pids tmp/sockets)
set :linked_files, %w(config/action_mailer.yml config/docker.yml.erb  config/code_ocean.yml config/database.yml config/newrelic.yml config/secrets.yml config/sendmail.yml config/smtp.yml config/mnemosyne.yml)
set :log_level, :info
set :puma_threads, [0, 16]
set :puma_workers, 4
set :puma_preload_app, true
set :repo_url, 'git@github.com:openHPI/codeocean.git'

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

namespace :deploy do
  before 'check:linked_files', 'config:push'

  after :compile_assets, :copy_vendor_assets do
    on roles(fetch(:assets_roles)) do
      within release_path do
        execute :cp, '-r', 'vendor/assets/javascripts/ace', 'public/assets/'
      end
    end
  end

  task :create_whenever_log_dir do
    on roles(:all) do
      within release_path do
        execute :mkdir, '-p', 'log/whenever'
      end
    end
  end
end

after :deploy, 'deploy:create_whenever_log_dir'
