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
begin
  require 'Win32API'

  class MEMORYSTATUS < Struct.new(:dwLength, :dwMemoryLoad, :dwTotalPhys, :dwAvailPhys, :dwTotalPageFile, :dwAvailPageFile, :dwTotalVirtual, :dwAvailVritualPhys)
  end

  def valid?
    true
  end

  def usage
    self.status.dwMemoryLoad
  end

  def total
    self.status.dwTotalPageFile.to_i
  end

  def status
    @__status__ ||= Win32API.new('kernel32', 'GlobalMemoryStatus', 'P', 'V')
    x = ([1] * 8).pack('LLIIIIII')
    @__status__.call(x)
    x = MEMORYSTATUS.new(*x.unpack('LLIIIIII'))
    x.dwMemoryLoad = 100.0 - 100.0 / x.dwTotalPageFile * x.dwAvailPageFile
    x
  end
rescue LoadError
  include Arbi::Modules::Acpi::Utils

  def valid?
    File.exist?('/proc/meminfo')
  end

  def usage
    stat = self.status
    100.0 - 100.0 / stat[:memtotal] * (stat[:memfree] + stat[:buffers] + stat[:cached])
  end

  def total
    self.status[:memtotal].to_i
  end

  def status
    hashize('/proc/meminfo')
  end
end

  def refresh
    @data = []

    usage = self.usage

    @data = [
      ("%.1f%%" % [usage]),
      ("%.1f%%" % [100.0 - usage]),
      self.total
    ]
  end

  def format
    tablize([['USED', 'FREE', 'SIZE'], @data])
  end
end

end

end
