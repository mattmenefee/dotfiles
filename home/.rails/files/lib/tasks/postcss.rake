# frozen_string_literal: true

namespace :postcss do
  desc 'Run PostCSS (autoprefixer) on the CSS build output'
  task build: :environment do
    system('yarn', 'build:css', exception: true)
  end
end

# dartsass:watch skips this step, so development CSS goes without vendor prefixes
Rake::Task['dartsass:build'].enhance do
  Rake::Task['postcss:build'].reenable
  Rake::Task['postcss:build'].invoke
end
