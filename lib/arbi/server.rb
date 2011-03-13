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

require 'eventmachine'
require 'arbi/modules'

module Arbi

class Server
  module Server
    def post_init
      send_data("OH HAI! ^_^\n")
    end

    def receive_data(data)
      if data.strip.downcase =~ /^(quit|exit)$/
        close_connection
        return
      end

      obj = Arbi.modules[data.strip.downcase]

      if obj
        send_data(obj.to_json)
      else
        send_data(Arbi::Modules::Error.new('Command doesn\'t exist').to_json)
      end
    rescue Exception => e
      Arbi.debug(e.to_s)
    end
  end

  def initialize(address = '127.0.0.1', port = 6969)
    @address  = address || '127.0.0.1'
    @port     = port    ||  6969
  end

  def start
    EventMachine.run {
      TimeLine.run
      EventMachine.start_server(@address, @port, Arbi::Server::Server)
      Arbi.debug("Starting server on #{@address}:#{@port}")
    }
  end

  def self.start(address = '127.0.0.1', port = 6969)
    self.new(address, port).start
  end
end

end
