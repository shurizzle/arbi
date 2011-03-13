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

class Thermal < Arbi::Modules::Module
  def initialize(data = [])
    super(data)
    @trips = {}
    @tempdirs = Dir.glob('/sys/class/thermal/thermal_zone*')

    @tempdirs.each {|dir|
      name = File.basename(dir)

      Dir.glob("#{dir}/trip_point_*").select {|x| x =~ /_temp$/ }.each {|trip|
        if File.read(trip.gsub(/emp$/, 'ype')).strip == 'critical'
          @trips[name] = "#{File.read(trip).to_i / 1000} C"
        end
      }
    }
  end

  def valid?
    !@tempdirs.empty?
  end

  def refresh
    @data = []

    @tempdirs.each {|dir|
      name = File.basename(dir)
      @data << {
        name:         name,
        temperature:  "#{File.read("#{dir}/temp").to_i / 1000} C",
        trip_point:   @trips[name]
      }
    }
  end

  def format
    tablize([['NAME', 'TEMPERATURE', 'TRIP POINT']] + @data.map {|therm|
      [therm[:name] || therm['name'], therm[:temperature] || therm['temperature'], therm[:trip_point] || therm['trip_point']]
    })
  end
end

end

end

end
