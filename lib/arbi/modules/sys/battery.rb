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

class Battery < Arbi::Modules::Module
  def initialize(data = [])
    super(data)
    @batteries = Dir.glob('/sys/class/power_supply/*').select {|dir| File.read("#{dir}/type").strip == 'Battery' }
  end

  def valid?
    !@batteries.empty?
  end

  def refresh
    @data = []

    @batteries.each {|battery|
      @data << self.battery_info(battery)
    }
    @data << self.average(@data)
  end

  def format
    tablize([['NAME', 'PERCENT', 'STATE', 'SANITY']] + @data.map {|x|
      [x[:name] || x['name'], x[:percent] || x['percent'], x[:state] || x['state'], x[:sanity] || x['sanity']]
    })
  end

protected
  def battery_info(dir)
    raw = {
      design_capacity:    File.read("#{dir}/energy_full_design").strip.to_i,
      last_full_capacity: File.read("#{dir}/energy_full").strip.to_i,
      remaining_capacity: File.read("#{dir}/energy_now").strip.to_i,
      present:            (File.read("#{dir}/present").strip.to_i.zero? ? false : true),
      charging_state:     File.read("#{dir}/status").strip.downcase.gsub(/^full$/, 'charged')
    }

    return not_present(File.basename(dir)) unless raw[:present]

    {
      name:     File.basename(dir),
      sanity:   ("%.1f%%" % [100.0 / raw[:design_capacity] * raw[:last_full_capacity]]),
      state:    raw[:charging_state],
      percent:  ("%.1f%%" % [100.0 / raw[:last_full_capacity] * raw[:remaining_capacity]])
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
      percent:  avg
    }
  end

  def not_present(name)
    {
      name:     name,
      sanity:   false,
      state:    false,
      percent:  false
    }
  end
end

end

end

end
