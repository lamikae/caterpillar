# encoding: utf-8
#--
# (c) Copyright 2008, 2010 Mikael Lammentausta
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

module Caterpillar
  class Usage
    def self.show
      STDOUT.puts %{
Usage:
  caterpillar --describe # gives you an overview of the tasks

For more information on usage in your Rails-portlet project,
see the README in the gem or at http://github.com/lamikae/caterpillar
      }
# XXX: write better usage for stdout
=begin
To start up a new JRuby Rails-portlet project:
  caterpillar rails project_name
=end
    end
  end
end
