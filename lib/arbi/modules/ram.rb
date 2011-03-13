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

class Ram < Arbi::Modules::Module
  include Arbi::Modules::Acpi::Utils

  def valid?
    File.exist?('/proc/meminfo')
  end

  def refresh
    @data = []

    mem = hashize('/proc/meminfo')
    perc = 100.0 / mem[:memtotal] * (mem[:memfree] + mem[:buffers] + mem[:cached])

    @data = [
      ("%.1f%%" % [100.0 - perc]),
      ("%.1f%%" % [perc])
    ]
  end

  def format
    tablize([['USED', 'FREE'], @data])
  end
end

end

end
