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

require File.join(File.dirname(__FILE__), '..', 'config')
begin
  require File.join(File.dirname(__FILE__), 'x11')
rescue
  module X11
    def self.delay
      [660, 25]
    end

    class Key
      def initialize(*args)
      end

      def press
      end

      def release
      end
    end

    class OneShotKey < Key
      undef_method :release
    end
  end
end
require 'eventmachine'

module Arbi
  def self.debug(str)
    $stderr.puts str
  end
end if !Arbi.respond_to?(:debug)

class File
  def self.busy?(file)
    File.open(file) {}
    false
  rescue Errno::EBUSY, Errno::EACCES
    true
  end
end

module EventMachine
  def file_tail(file, handler = nil, *args, &blk)
    self.attach(File.open(file), handler, *args, &blk)
  end
end

module Arbi
  class Server
    class Acpi
      ACPI_EVENT = '/proc/acpi/event'

      class Server
        def initialize(path = Config[:server][:acpi][:bind])
          @channel = EventMachine::Channel.new

          @server = EventMachine.start_unix_domain_server(path, BroadcastServer.new(@channel))
          Arbi.debug("Server started at #{path}")
          File.chmod(0766, path)
          EventListener.new(self)
        rescue
          Arbi.debug("Error reading ACPI keys")
          EventMachine.stop_server(@server) rescue nil
        end

        def <<(data)
          @channel << data
        end
      end

      class BroadcastServer
        def self.new(channel)
          Module.new {
            define_method(:post_init) {
              @sid = channel.subscribe {|data|
                send_data(data)
              }
            }

            define_method(:unbind) {
              channel.unsubscribe @sid
            }
          }
        end
      end

      class Reader
        def self.new(server)
          Module.new {
            define_method(:receive_data) {|data|
              server << data
            }
          }
        end
      end

      class EventListener
        def self.new(server)
          if File.busy?(ACPI_EVENT)
            EventMachine.connect_unix_domain(Config[:server][:acpi][:listen], Reader.new(server))
            Arbi.debug("Reading from #{Config[:server][:acpi][:listen]}")
          else
            EventMachine.file_tail(ACPI_EVENT, Reader.new(server))
            Arbi.debug("Reading from #{ACPI_EVENT}")
          end
        end
      end

      def self.run
        Server.new
      end

      def self.delay
        delay, interval = X11.delay
        delay ||= 660
        interval ||= 25

        [delay, interval]
      end
    end
  end
end

if __FILE__ == $0
  EventMachine.run {
    Arbi::Server::Acpi.run
  }
end
