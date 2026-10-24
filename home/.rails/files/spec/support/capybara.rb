# frozen_string_literal: true

# The chrome channel drives the installed Google Chrome, so no Playwright browser download is needed
Capybara.register_driver :playwright_chrome do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    channel: 'chrome',
    headless: ENV['CAPYBARA_HEADED'].blank?,
    # Shared memory is small in CI containers, where Chrome otherwise crashes
    args: %w[--disable-gpu --disable-dev-shm-usage],
    # Playwright counts milliseconds, Capybara seconds
    timeout: (Capybara.default_max_wait_time * 1000).to_i
  )
end

RSpec.configure do |config|
  config.before(:each, type: :system) { driven_by :rack_test }
  # Defined second, so it overrides rack_test for specs that need JavaScript
  config.before(:each, :js, type: :system) { driven_by :playwright_chrome }
end
