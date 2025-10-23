# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

task default: :test

namespace :sorbet do
  desc "Run Sorbet type checker"
  task :check do
    sh "bundle exec srb tc"
  end

  desc "Generate RBI files using Tapioca"
  task :generate do
    puts "Generating RBI files for gems..."
    sh "bundle exec tapioca gems"

    puts "\nGenerating RBI files for DSL..."
    sh "bundle exec tapioca dsl" do |ok, _res|
      # DSL generation may fail if no DSL compilers match, which is fine
      puts "No DSL files generated (this is normal if you don't have DSL code)" unless ok
    end

    puts "\nRBI generation complete!"
  end

  desc "Generate RBI files and run type checker"
  task all: [:generate, :check]
end
