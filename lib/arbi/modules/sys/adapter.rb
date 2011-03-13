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

module Arbi

module Modules

module Sys

class Adapter < Arbi::Modules::Module
  def initialize(data = [])
    super(data)
    @adapters = Dir.glob('/sys/class/power_supply/*').select {|ad|
      File.read("#{ad}/type").strip == 'Mains'
    }
  end

  def valid?
    !@adapters.empty?
  end

  def refresh
    @data = []

    @adapters.each {|adapter|
      @data << {
        name:   File.basename(adapter),
        state:  (File.read("#{adapter}/online").to_i.zero? ? false : true)
      }
    }
  end

  def format
    tablize([['NAME', 'STATE']] + @data.map {|adapter|
      [adapter[:name] || adapter['name'], (adapter[:state] || adapter['state']) ? 'on' : 'off']
    })
  end
end

end

end

end
