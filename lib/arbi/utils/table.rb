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

def tablize(args)
  lens, res, div = [], "", ""

  args.each {|row|
    row.each_with_index {|e, i|
      lens[i] ||= 0
      lens[i] = [lens[i], e.to_s.length].max
    }
  }

  div = ?+ + lens.map {|s|
    (?- * s) + ?+
  }.join

  res += div + "\n"

  args.each_with_index {|row, index|
    res += ?|
    row.each_with_index {|e, i|
      res += (e || ?-).to_s.center(lens[i]) + ?|
    }

    res += "\n" + div if index == 0

    res += "\n"
  }

  res += div + "\n"
end
