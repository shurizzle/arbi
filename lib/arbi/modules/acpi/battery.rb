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

require 'arbi/modules/acpi/utils'

module Arbi

module Modules

module Acpi

class Battery < Arbi::Modules::Module
  include Arbi::Modules::Acpi::Utils

  def initialize(data = [])
    super(data)
    @batteries = Dir.glob("/proc/acpi/battery/*")
  end

  def valid?
    File.exist?('/proc/acpi/battery') and !@batteries.empty?
  end

  def refresh
    @data = []

    @batteries.each {|battery|
      @data << self.battery_info(battery)
    }
    @data << self.average(@data)
  end

  def format
    tablize([['NAME', 'PERCENT', 'STATE', 'SANITY', 'REMAINING']] + @data.map {|x|
      [x[:name] || x['name'], x[:percent] || x['percent'], x[:state] || x['state'],
        x[:sanity] || x['sanity'], x[:remain] || x['remain']]
    })
  end

protected
  def battery_info(dir)
    raw = self.hashize(dir + '/info').merge(self.hashize(dir + '/state'))
    # Return if battery isn't present
    return not_present(File.basename(dir)) unless {yes: true, no: false}[(raw[:present].to_sym rescue nil)]

    # time remaining
    remain =  if raw[:charging_state] == 'discharging'
                total = raw[:remaining_capacity].to_f / raw[:present_rate]
                hours = total.floor
                "%dh%dm" % [hours, ((total - hours) * 60).floor]
              else
                false
              end

    {
      name:     File.basename(dir),
      sanity:   ("%.1f%%" % [100.0 / raw[:design_capacity] * raw[:last_full_capacity]]),
      state:    raw[:charging_state],
      percent:  ("%.1f%%" % [100.0 / raw[:last_full_capacity] * raw[:remaining_capacity]]),
      remain:   remain
    }
  end

  def average(batteries)
    avg, n = 0, 0

    batteries.each {|battery|
      avg += battery[:percent].gsub(/%$/, '').to_f and n += 1 if battery[:percent]
    }
    avg = "%.1f%%" % [avg / n] rescue false

    {
      name:     'AVERAGE',
      sanity:   false,
      state:    false,
      remain:   false,
      percent:  avg
    }
  end

  def not_present(name)
    {
      name:     name,
      sanity:   false,
      state:    false,
      percent:  false,
      remain:   false
    }
  end
end

end

end

end
