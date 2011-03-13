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

require 'arbi/client'

module Arbi
  class << self
    def connect(address = '127.0.0.1', port = 6969)
      @@connection = Arbi::Client.new(address, port)
    end

    def connected?
      @@connection ? true : false
    end

    def connection
      @@connection.sock
    end

    def get(what)
      self.connect unless self.connected?
      @@connection.get(what)
    end
  end
end
