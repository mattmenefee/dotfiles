# frozen_string_literal: true

# Replaces the gem's defaults, dropping --no-source-map so CSS gets source maps like the JavaScript
Rails.application.config.dartsass.build_options = [
  '--style=compressed',
  # Bootstrap 5 still uses @import and the global Sass functions that Dart Sass deprecates
  '--silence-deprecation=color-functions,global-builtin,import,if-function',
  # Lets @import and @use resolve npm packages without adding node_modules to Propshaft's paths
  '--load-path', Rails.root.join('node_modules').to_s
]
