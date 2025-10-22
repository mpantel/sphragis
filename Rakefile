# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

# Brakeman security scanner
begin
  require "brakeman"

  desc "Run Brakeman security scanner"
  task :brakeman do
    require "brakeman"
    result = Brakeman.run(
      app_path: ".",
      print_report: true,
      config_file: "config/brakeman.yml"
    )
    exit Brakeman::Warnings_Found_Exit_Code if result.filtered_warnings.any?
  end
rescue LoadError
  # Brakeman not available
end

task default: :test
