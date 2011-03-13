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

class Adapter < Arbi::Modules::Module
  include Arbi::Modules::Acpi::Utils

  def initialize(data = [])
    super(data)
    @adapters = Dir.glob('/proc/acpi/ac_adapter/*')
  end

  def valid?
    !@adapters.empty?
  end

  def refresh
    @data = []

    @adapters.each {|adapter|
      @data << {
        name:   File.basename(adapter),
        state:  (hashize("#{adapter}/state")[:state] == 'on-line' ? true : false)
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
