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

class Numeric

module Scalar
  attr_accessor :unit

  MULTIPLIERS = {
    ?Y => 10 ** 24, ?Z => 10 ** 21, ?E => 10 ** 18,
    ?P => 10 ** 15, ?T => 10 ** 12, ?G => 10 ** 9,
    ?M => 10 ** 6, ?k => 10 ** 3, ?h => 10 ** 2, 'da' => 10,

    ?y => 10 ** -24, ?z => 10 ** -21, ?a => 10 ** -18,
    ?f => 10 ** -15, ?p => 10 ** -12, ?n => 10 ** -9,
    ?u => 10 ** -9, ?m => 10 ** -3, ?c => 10 ** -2, ?d => 10 ** -1
  }

  alias __method_missing__ method_missing
  def method_missing(sym, *args, &blk)
    if MULTIPLIERS.include?(sym.to_s)
      self / MULTIPLIERS[sym.to_s]
    else
      self.__method_missing__(sym, *args, &blk) if sym != :to_str
    end
  end
end

  def self.parse(str)
    if str.strip.match(/^([^\s]+)\s+(#{Numeric::Scalar::MULTIPLIERS.keys.map {|x|
          Regexp.escape(x)
          }.join(?|)})?(.*?)$/)
      num, mul, unit = $1, $2, $3
      v = begin
        Integer(num)
      rescue ArgumentError
        Float(num) rescue nil
      end

      return nil unless v

      if Numeric::Scalar::MULTIPLIERS[mul]
        v = (v * Numeric::Scalar::MULTIPLIERS[mul]).to_f
      end

      if !unit.empty?
        v.unit = unit.dup
      end

      return v
    end
  end
end

class Integer
  include Numeric::Scalar
end

class Float
  include Numeric::Scalar
end

class Rational
  include Numeric::Scalar
end
