#--
# Copyleft shura. [ shura1991@gmail.com ]
#
# This file is part of arbi.
#
# arbi is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# arbi is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with arbi. If not, see <http://www.gnu.org/licenses/>.
#++

require 'json'
require 'singleton'
require 'arbi/config'
require 'arbi/timeline'
require 'arbi/utils/table'
require 'arbi/utils/numeric'

module Arbi

module Modules
  PATH = [File.join(File.dirname(__FILE__), 'modules')]

  @@logger  = STDERR

  class Error
    def initialize(data = "")
      @data = data
    end

    def to_json(*a)
      ({
        'json_class'  => self.class.name,
        'data'        => @data
      }.to_json(*a)) + "\n"
    end

    def format
      @data
    end

    def self.json_create(o)
      self.new(o['data'])
    end
  end

  class Module
    attr_reader :data

    def initialize(data = [])
      @data = data
    end

    def every(ev = 2, args = {}, &blk)
      args[:timeout] ||= 5
      TimeLine::Job.new(ev, args[:timeout], &blk)
    end

    def to_json(*a)
      self.refresh if self.respond_to?(:refresh)

      {
        'json_class'  => self.class.to_s,
        'data'        => @data
      }.to_json(*a) + "\n"
    end

    def format
      "#{self.class.name} has no format specified, writing raw:\n#{data.to_json}"
    end

    def valid?
      false
    end

    class << self
      def json_create(o)
        self.new(o['data'])
      end

      def inherited(obj)
        @@modules ||= {}
        Singleton.__init__(obj)
        Arbi::Modules.uninit
        @@modules[obj.name] = obj
      end

      def modules
        @@modules
      end

      def name
        self.to_s.downcase.split('::').last
      end

      alias __method_missing__ method_missing
      def method_missing(sym, *args, &blk)
        if self.instance.respond_to?(sym)
          self.instance.send(sym, *args, &blk)
        else
          self.__method_missing__(sym, *args, &blk)
        end
      end

      undef_method :to_json
    end
  end

  class << self
    @@init = false

    def modules
      Arbi::Modules::Module.modules.dup
    end

    def init
      return if self.initialized?
      Arbi::Modules::Module.modules.replace(
        Hash[Arbi::Modules::Module.modules.to_a.select {|(key, value)|
          value.valid?
      }])
      @@init = true
    end

    def uninit
      @@init = false
    end

    def initialized?
      @@init
    end
  end
end

def self.debug(str)
  @@logger.puts(str.to_s)
rescue
  STDERR.puts(str.to_s)
end

def self.init
  Arbi::Modules.init
end

def self.modules
  Arbi.init
  Arbi::Modules.modules
end

end

def load_module(file)
  lp = $:.dup
  $:.replace(Arbi::Config[:modules][:path] + $:)
  require file
rescue Exception => e
  Arbi.debug("Error loading module: #{e}")
ensure
  $:.replace(lp)
end

load_module('help')
load_module('version')
load_module('cpu')
load_module('ram')
load_module('net')
load_module('adapter')
load_module('battery')
load_module('diskstat')

Arbi::Config[:modules][:modules].each {|mod|
  load_module(mod)
}

Arbi.init
