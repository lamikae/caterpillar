# (c) Copyright 2008,2009,2010 Mikael Lammentausta
#
# See the file LICENSES.txt included with the distribution for
# software license details.

# Rake task.  Allows defining multiple configurations inside the same
# Rakefile by using different task names.
module Caterpillar
  class << self
    attr_writer :project_application

    def project_application
      @project_application || Rake.application
    end
  end

  class RailsTask < Rake::TaskLib

    # Task name 
    attr_accessor :name

    # Required Gems
    attr_accessor :required_gems

    def initialize(name = :usage, config = nil, tasks = :define_tasks)
      @name   = name
      @required_gems = %w(rails caterpillar jruby-jars warbler)
      
      yield self if block_given?
      send tasks
    end

    def define_tasks
      define_rails_task
    end

    def define_rails_task
      task :rails do
        exit 1 unless check 'required gems' do 
          check_required_gems
        end
        exit 1 unless check 'JRuby binary' do
          check_jruby
        end
        exit 1 unless check 'required gems in JRuby' do
          check_jruby_required_gems
        end
        exit 1 unless check 'Rails binary' do
          check_rails
        end
      end
    end

    private

    def check_required_gems
      gems = @required_gems
      available_gems = []

      gems.each {|gem| available_gems << gem if Gem::available? gem}
      gems_not_found = (gems - available_gems)

      if gems_not_found.empty?
        return true
      else
        return "These required gems were not found: #{gems_not_found.join(' ')}"
      end
    end

    def check_jruby
      has_jruby = system 'jruby --copyright >/dev/null 2>&1'
      
      if has_jruby
        return true
      else
        return 'jruby binary was not found in your path'
      end
    end

    def check_jruby_required_gems
      jruby_gems = `jruby -S gem list`
      available_gems = []
      
      @required_gems.each {|gem| available_gems << gem if jruby_gems.match(gem)}
      gems_not_found = (@required_gems - available_gems)

      if gems_not_found.empty?
        return true
      else
        return "These required gems were not found: #{gems_not_found.join(' ')}"
      end
    end

    def check_rails
      has_rails = system 'rails --version >/dev/null'
      
      if has_rails
        return true
      else
        return 'rails binary was not found in your path'
      end
    end

    def check(message)
      STDOUT.print "Checking for #{message}..."

      result = yield

      if result.class == String
        puts_failed
        puts message
        return false
      else
        puts_ok
        return true
      end
    end
      
    def puts_ok
      STDOUT.puts "\e[32mOK\e[0m"
    end

    def puts_failed
      STDOUT.puts "\e[31mFAILED\e[0m"
    end
  end

end
