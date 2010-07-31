# encoding: utf-8
#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  class Usage
    def self.show
      STDOUT.puts 'Usage:'
      STDOUT.puts '  See "%s --describe" for an overview of the tasks.' % $0
      STDOUT.puts       
      STDOUT.puts 'How to start up a new rails-portlet project?'
      STDOUT.puts '  caterpillar rails project_name'
      STDOUT.puts
    end
  end
end
