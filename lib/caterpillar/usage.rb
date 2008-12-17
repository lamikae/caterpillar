#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  class Usage
    def self.show
puts 'Caterpillar v.%s (c) Copyright 2008 Mikael Lammentausta' % VERSION
puts 'Caterpillar is provided under the terms of the MIT license.'
puts
puts 'Usage:'
puts '  See "%s --describe" for an overview of the tasks.' % $0
puts
puts '  cd to Rails root, and run the "%s pluginize" task' % $0
# puts '  Run "%s" in Rails root' % $0
# puts '  See 
    end
  end
end
