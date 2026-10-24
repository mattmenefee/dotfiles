# frozen_string_literal: true

# Application template that ~/.railsrc passes to every `rails new`. It assumes the .railsrc flags:
# esbuild through jsbundling-rails, no Minitest, no omakase RuboCop and no Solid Queue

def source_paths
  # Keeps the generator's own paths, which later Rails steps (such as Kamal's) read templates from
  [File.join(__dir__, 'files'), *super]
end

# Thor's uncomment_lines does nothing when the line has moved; this raises instead
def uncomment_lines!(path, flag)
  gsub_file! path, /^(\s*)#[[:blank:]]?(.*#{flag.source})/, '\1\2'
end

gem 'dartsass-rails'
gem 'haml-rails'
gem 'sidekiq'
# Without Solid Cable, production Action Cable uses the Redis adapter
uncomment_lines! 'Gemfile', /gem "redis"/

# A second gem_group for the same groups trips Bundler/DuplicatedGroup
inject_into_file! 'Gemfile', after: "group :development, :test do\n" do
  <<~RUBY.indent(2)
    gem "factory_bot_rails"
    gem "rspec-rails"
  RUBY
end

# The Dockerfile installs every group but development, so this keeps the linter out of images
inject_into_file! 'Gemfile', after: "group :development do\n" do
  <<~RUBY.indent(2)
    gem "rubocop", require: false
    gem "rubocop-capybara", require: false
    gem "rubocop-factory_bot", require: false
    gem "rubocop-performance", require: false
    gem "rubocop-rails", require: false
    gem "rubocop-rake", require: false
    gem "rubocop-rspec", require: false
    gem "rubocop-rspec_rails", require: false
  RUBY
end

gem_group :test do
  gem 'capybara'
  gem 'capybara-playwright-driver'
  gem 'shoulda-matchers'
end

def setup_rspec
  generate 'rspec:install'
  uncomment_lines! 'spec/rails_helper.rb', %r{Rails\.root\.glob\('spec/support}
  directory 'spec/support'
  copy_file 'lib/tasks/spec_assets.rake'
end

def setup_playwright
  # playwright-ruby-client drives the browser through the npm package, which must match its version
  version = File.read('Gemfile.lock')[/^    playwright-ruby-client \(([\d.]+)\)/, 1]
  raise Thor::Error, 'playwright-ruby-client is missing from Gemfile.lock' unless version

  run "yarn add --dev --exact playwright@#{version}"
end

def setup_esbuild
  copy_file 'esbuild.config.mjs'
  run 'npm pkg set scripts.build="node esbuild.config.mjs"'
end

def setup_bootstrap
  # Unlike run, rails_command doesn't abort on failure unless asked
  rails_command 'dartsass:install', abort_on_failure: true
  run 'yarn add bootstrap @popperjs/core'
  append_to_file 'app/javascript/application.js', %(import "bootstrap"\n)
  # The stub shares the logical path application.css with the dartsass build, which it would shadow
  remove_file 'app/assets/stylesheets/application.css'
  copy_file 'app/assets/stylesheets/application.scss', force: true
  copy_file 'config/initializers/dartsass.rb'
end

def setup_postcss
  run 'yarn add --dev autoprefixer postcss postcss-cli'
  run 'npm pkg set scripts.build:css="postcss app/assets/builds/*.css --replace"'
  copy_file 'postcss.config.js'
  copy_file 'browserslistrc', '.browserslistrc'
  copy_file 'lib/tasks/postcss.rake'
end

def setup_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq'
  # rspec-rails' job matchers need the test adapter, which also keeps specs from needing Redis
  environment 'config.active_job.queue_adapter = :test', env: 'test'
  append_to_file 'Procfile.dev', "worker: bundle exec sidekiq\n"
end

def setup_kamal
  # REDIS_URL carries the accessory's password, so it is a secret rather than clear env
  inject_into_file! 'config/deploy.yml', "    - REDIS_URL\n", after: "    - RAILS_MASTER_KEY\n"
  accessory = File.read(find_in_source_paths('kamal/redis_accessory.yml'))
  append_to_file 'config/deploy.yml', "\n#{accessory}"
  setup_kamal_secrets
end

def setup_kamal_secrets
  # Kamal names the accessory container <service>-redis, and Rails names the service after the app
  append_to_file '.kamal/secrets', <<~SECRETS

    # Valkey's password, generated into the app's credentials by rails new
    REDIS_PASSWORD=$(bin/rails credentials:fetch redis.password)
    REDIS_URL=redis://:$REDIS_PASSWORD@#{app_name}-redis:6379/0
  SECRETS
  run "bin/rails runner #{find_in_source_paths('kamal/redis_password.rb')}"
end

def setup_kamal_worker
  # Rails' commented job role runs Solid Queue's bin/jobs, which --skip-solid leaves out. It shares
  # the web host, where REDIS_URL's container name resolves. The bang raises if Rails changes the
  # block, rather than deploying with no worker.
  gsub_file! 'config/deploy.yml', %r{^  # job:\n(?:  # .*\n)*?  #   cmd: bin/jobs\n} do |role|
    role.gsub(/^  # /, '  ').sub('bin/jobs', 'bundle exec sidekiq')
  end
end

def setup_haml_layouts
  # haml-rails generates HAML views but leaves the ERB layouts Rails created
  %w[application.html mailer.html mailer.text].each do |layout|
    remove_file "app/views/layouts/#{layout}.erb"
  end
  template 'app/views/layouts/application.html.haml.tt'
  copy_file 'app/views/layouts/mailer.html.haml'
  copy_file 'app/views/layouts/mailer.text.haml'
end

def setup_ci
  # -T and --skip-rubocop drop Rails' lint and test jobs and bin/ci steps; these restore them
  jobs = File.read(find_in_source_paths('github/ci_jobs.yml'))
  append_to_file '.github/workflows/ci.yml', "\n#{jobs.indent(2)}"
  insert_into_file! 'config/ci.rb', %(  step "Style: Ruby", "bin/rubocop"\n),
                    after: /^  step "Setup".*\n/
  insert_into_file! 'config/ci.rb', <<~RUBY.indent(2), after: /^  step "Security: Brakeman.*\n/
    step "Tests: RSpec", "bin/rails spec"
    step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
  RUBY
end

def setup_database
  # Writes db/schema.rb, which db:prepare skips without a migration and CI's db:test:prepare needs
  rails_command 'db:create db:migrate', abort_on_failure: true
end

def setup_rubocop
  copy_file 'rubocop.yml', '.rubocop.yml'
  run 'bundle binstubs rubocop'
  # Exits 1 on the offenses autocorrect leaves, which would otherwise abort `rails new`
  run 'bin/rubocop -A --format quiet', abort_on_failure: false
  # Records what autocorrect cannot fix in the generated code, so the new app starts green
  run 'bin/rubocop --auto-gen-config --format quiet'
end

after_bundle do
  setup_rspec
  setup_esbuild
  setup_bootstrap
  setup_postcss
  setup_playwright
  setup_sidekiq
  setup_kamal
  setup_kamal_worker
  setup_haml_layouts
  setup_ci
  setup_database
  setup_rubocop
end
