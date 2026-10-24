# frozen_string_literal: true

# Application template that ~/.railsrc passes to every `rails new`. It assumes the .railsrc flags:
# esbuild through jsbundling-rails, no Minitest, no omakase RuboCop and no Solid Queue

def source_paths
  # Keeps the generator's own paths, which later Rails steps (such as Kamal's) read templates from
  [File.join(__dir__, 'files'), *super]
end

gem 'dartsass-rails'
gem 'haml-rails'
gem 'sidekiq'
# Without Solid Cable, production Action Cable uses the Redis adapter
uncomment_lines 'Gemfile', /gem "redis"/

# A second gem_group for the same groups trips Bundler/DuplicatedGroup
inject_into_file 'Gemfile', after: "group :development, :test do\n" do
  <<~RUBY.indent(2)
    gem "factory_bot_rails"
    gem "rspec-rails"
  RUBY
end

gem_group :test do
  gem 'capybara'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'shoulda-matchers'
end

def setup_rspec
  generate 'rspec:install'
  uncomment_lines 'spec/rails_helper.rb', %r{Rails\.root\.glob\('spec/support}
  directory 'spec/support'
end

def setup_esbuild
  copy_file 'esbuild.config.mjs'
  run 'npm pkg set scripts.build="node esbuild.config.mjs"'
end

def setup_bootstrap
  rails_command 'dartsass:install'
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
  copy_file 'lib/tasks/postcss.rake'
end

def setup_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq'
  append_to_file 'Procfile.dev', "worker: bundle exec sidekiq\n"
end

def setup_kamal
  service = YAML.load_file('config/deploy.yml').fetch('service')
  # Kamal names the accessory container <service>-redis on the network it shares with the app
  gsub_file 'config/deploy.yml', "  # clear:\n", <<~YAML.indent(2)
    clear:
      REDIS_URL: redis://#{service}-redis:6379/0
  YAML
  accessory = File.read(find_in_source_paths('kamal/redis_accessory.yml'))
  append_to_file 'config/deploy.yml', "\n#{accessory}"
end

def setup_kamal_worker
  # Rails' commented job role runs Solid Queue's bin/jobs, which --skip-solid leaves out. It shares
  # the web host, where REDIS_URL's container name resolves. The bang raises if Rails changes the
  # block, rather than deploying with no worker.
  gsub_file! 'config/deploy.yml', %r{^  # job:\n(?:  # .*\n)*?  #   cmd: bin/jobs\n} do |role|
    role.gsub('  # ', '  ').sub('bin/jobs', 'bundle exec sidekiq')
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
  setup_sidekiq
  setup_kamal
  setup_kamal_worker
  setup_haml_layouts
  setup_rubocop
end
