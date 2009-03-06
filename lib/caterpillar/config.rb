#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  # Portlet configuration. The config file 'config/portlets.rb' should be installed in your Rails application. See the comments in the configuration file for more specific information about each option.
  class Config
    FILE = "config/portlets.rb"

    # Are all named routes used, or only the ones specifically defined in the config FILE?
    attr_accessor :include_all_named_routes

    attr_accessor :category

    attr_accessor :host

    attr_accessor :servlet

    attr_accessor :instances

    attr_reader   :rails_root

    attr_accessor :_container

    attr_accessor :javascripts

    attr_accessor :routes

    attr_accessor :warbler_conf

    # Sets sane defaults that are overridden in the config file.
    def initialize
      @rails_root  = File.expand_path(defined?(RAILS_ROOT) ? RAILS_ROOT : Dir.getwd)
      @servlet = File.basename(@rails_root)
      @category = @servlet
      @instances = []
      @javascripts = []
      @include_all_named_routes = true
      @warbler_conf = File.join(@rails_root,'config','warble.rb')
      STDERR.puts 'Warbler configuration file could not be found' unless File.exists?(@warbler_conf)

      yield self if block_given?
    end

    # The container class is used for parsing XML files.
    #
    # Possible values: Liferay (default)
    def container
      self._container || Caterpillar::Liferay.new
    end

    # Accepts the configuration option, and instantates the container class.
    def container=(_class)
      self._container = _class.new
    end


  end
end