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

require 'sys/filesystem'

module Arbi

module Modules

module Sys
  include ::Sys
end

class Diskstat < Module
  def valid?
    true
  end

  def refresh
    @data = []
    self.devices.each {|device|
      begin
        diskstat = Sys::Filesystem.stat(device[:point])
        device.merge!({
          usage: "#{100 - (100.0 / diskstat.blocks  * diskstat.blocks_available).round}%",
          space:  self.unitize(diskstat.blocks * diskstat.fragment_size)
        })

        @data << device
      rescue
      end
    }
  end

  def format
    tablize([['DEVICE', 'POINT', 'USE', 'SPACE']] + @data.map {|dev|
      [dev[:device] || dev['device'], dev[:point] || dev['point'], dev[:usage] || dev['usage'],
        dev[:space] || dev['space']]
    })
  end

protected
  def devices
    Sys::Filesystem.mounts.map {|fs|
      {device: fs.name, point: fs.mount_point}
    }
  end

  def unitize misure
    u = 'b'
    %w(Kb Mb Gb Tb).each {|i|
      if misure >= 1024
        misure /= 1024.0
        u = i
      else
        return misure.round.to_s + u
      end
    }
    misure.round.to_s + u
  end
end

end

end
