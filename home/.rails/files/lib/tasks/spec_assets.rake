# frozen_string_literal: true

# dartsass-rails builds on test:prepare, which an RSpec app lacks, so specs would see stale CSS
Rake::Task['spec:prepare'].enhance(['dartsass:build'])
