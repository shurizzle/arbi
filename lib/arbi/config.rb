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

require 'yaml'
require 'singleton'

module Arbi

class Config < Hash
  include Singleton

  def initialize
    super()
    self.parse
  end

  def parse(file = '/etc/arbi.yaml')
    config = ::YAML.load_file(file)
  rescue Exception => e
    Arbi.debug "Config: #{e}"
  ensure
    config ||= {}
    config[:server] ||= {}
    config[:server][:address] ||= '127.0.0.1'
    config[:server][:port] ||= 6969
    config[:server][:acpi] ||= {}
    config[:server][:acpi][:listen] ||= '/var/run/acpid.socket'
    config[:server][:acpi][:bind] ||= '/var/run/arbid.socket'
    config[:client] ||= {}
    config[:client][:address] ||= '127.0.0.1'
    config[:client][:port] ||= 6969
    config[:client][:default_cmd] ||= ['help', 'quit']
    config[:modules] ||= {}
    config[:modules][:path] ||= []
    config[:modules][:modules] ||= []

    config[:client][:default_cmd].map!(&:to_s).uniq!
    config[:client][:default_cmd].delete('quit')
    config[:client][:default_cmd] << 'quit'
    config[:modules][:path] << File.join(File.dirname(__FILE__), 'modules')
    config[:modules][:path].uniq!

    self.replace(config)
  end

  class << self
    alias __method_missing__ method_missing
    def method_missing(sym, *args, &blk)
      if self.instance.respond_to?(sym)
        self.instance.send(sym, *args, &blk)
      else
        self.__method_missing__(sym, *args, &blk)
      end
    end

    def [](*args)
      self.instance.send(:[], *args)
    end

    def []=(*args)
      self.instance.send(:[]=, *args)
    end

    def inspect
      self.instance.inspect
    end

    def to_s
      self.instance.to_s
    end
  end
end

end
