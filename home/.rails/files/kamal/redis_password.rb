# frozen_string_literal: true

# Run with bin/rails runner during rails new, so the first deploy has a Valkey password to fetch
credentials = Rails.application.credentials
credentials.write("#{credentials.read}\nredis:\n  password: #{SecureRandom.hex(32)}\n")
