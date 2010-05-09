# encoding: utf-8


#--
# (c) Copyright 2008 Mikael Lammentausta
# See the file LICENSES.txt included with the distribution for
# software license details.
#++

module Caterpillar
  # Portlet configuration. The config file 'config/portlets.rb' should be installed in your Rails application. See the comments in the configuration file for more specific information about each option.
  class Config
    FILE = File.join('config','portlets.rb')
    JRUBY_HOME = nil # override in the config file if necessary

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

    attr_accessor :logger

    # Sets sane defaults that are overridden in the config file.
    def initialize
      # RAILS_ROOT is at least defined in Caterpillar initialization
      @rails_root  = File.expand_path(RAILS_ROOT)
      @servlet = nil
      @category = nil
      @instances = []
      @javascripts = []
      @include_all_named_routes = true

      rails_conf = File.join(@rails_root,'config','environment.rb')
      unless File.exists?(rails_conf)
        STDERR.puts 'Rails configuration file could not be found'
        @rails_root = nil
      else
        @servlet = File.basename(@rails_root)
        @category = @servlet

        @warbler_conf = File.join(@rails_root,'config','warble.rb')
        unless File.exists?(@warbler_conf)
          #STDERR.puts 'Warbler configuration file could not be found'
        end
      end

      #@logger  = (defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new)

      yield self if block_given?
    end

    # The container class is used for parsing XML files.
    #
    # Possible values: Caterpillar::Liferay (default using Tomcat)
    def container
      self._container || Caterpillar::Liferay.new
    end

    # Accepts the configuration option, and instantates the container class.
    def container=(_class)
      self._container = _class.new
    end


  end
end
