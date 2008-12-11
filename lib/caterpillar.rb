#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++


# Caterpillar helps you with building Rails applications to be used in Java
# JSR286 portlets. This is possible with the help of +Rails-portlet+.
#
# Rails portlets have been used on Liferay and the helpers offer specialized methods to support better Liferay integration.
#
# This package offers these functionalities:
#
#  - processes the portlet XML configuration in accordance with the named routes
# See Config
#
#  - provides a navigation view in development (you will have to enable it manually)
# See Navigation
#
#  - offers a set of migrations to help with Liferay integration
#
#  - provides a Rake task 'extract_fixtures', which imports live data
#    from the production database for testing
#
module Caterpillar
end

file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(file))

require 'find'

# include all ruby files
Find.find(this_dir) do |file|
  if FileTest.directory?(file)
    if File.basename(file) == 'deprecated'
      Find.prune # Don't look any further into this directory.
    else
      next
    end
  else
    require file if file[/.rb$/]
  end
end