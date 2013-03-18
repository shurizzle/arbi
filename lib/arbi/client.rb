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

require 'socket'
require 'arbi/modules'

module Arbi

class Client
  attr_reader :sock

  def initialize(address = '127.0.0.1', port = 6969)
    @address  = address || '127.0.0.1'
    @port     = port || 6969

    self.connect
  end

  def connect
    @sock = TCPSocket.new(@address, @port)
    @sock.gets
  end

  def get(what = 'help')
    @sock.print "#{what.strip}\r\n"
    @sock.flush
    JSON.parse(@sock.gets.strip, create_additions: true)
  rescue Errno::EPIPE
    self.connect
    retry
  rescue NoMethodError
    nil
  end
end

end
