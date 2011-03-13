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

module Acpi

  module Utils
  protected

    def hashize(file)
      h = {}

      File.readlines(file).each {|line|
        if (line =~ /^([^:]+):\s*(.+?)\s*$/)
          key, value = $1, $2
          key = key.downcase.gsub(/ /, '_')
          value = Numeric.parse(value) || value
          h[key] = value
          h[key.to_sym] = value
        end
      } if File.exist?(file)

      h
    end
  end

end

end

end
