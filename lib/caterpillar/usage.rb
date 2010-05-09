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
      STDOUT.puts '  cd to Rails root, and run the "%s pluginize" task' % $0
      STDOUT.puts
    end
  end
end
