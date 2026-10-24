# frozen_string_literal: true

Rails.application.config.dartsass.build_options = [
  '--style=compressed',
  # Bootstrap 5 still uses @import and the global Sass functions that Dart Sass deprecates
  '--silence-deprecation=color-functions,global-builtin,import,if-function',
  # Lets @use resolve npm packages without adding node_modules to Propshaft's asset paths
  '--load-path', Rails.root.join('node_modules').to_s
]
