# frozen_string_literal: true

Delayed::Worker.sleep_delay = 2
Delayed::Worker.max_attempts = 10
Delayed::Worker.max_run_time = 5.minutes
