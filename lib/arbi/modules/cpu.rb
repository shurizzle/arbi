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

class Cpu < Arbi::Modules::Module
  def initialize(data = [])
    super(data)

    @mutex = Mutex.new
    @prev = {:idle => {}, :total => {}}
    @datas = []

    every 2, :timeout => 10, &self.method(:update)
  end

  def valid?
    File.exist?('/proc/stat')
  end

  def refresh
    @mutex.synchronize {
      @data = @datas.dup
    }
  end

  def format
    tablize([['NAME', 'PERCENT']] + @data.map {|x|
      [x[:name] || x['name'], x[:percent] || x['percent']]
    })
  end

protected
  def update
    percents = {}
    File.readlines('/proc/stat').each {|line|
      if line =~ /^cpu/
        name, *datas = line.split(/\s+/)
        name = (name == 'cpu' ? 'AVERAGE' : name)
        total = datas.map(&:to_i).inject(:+)
        idle = datas[3].to_i

        @prev[:idle][name] = @prev[:total][name] = 0 if !@prev[:idle].include?(name) or !@prev[:total].include?(name)

        percents[name] = "#{100 * ((total - @prev[:total][name]) - (idle - @prev[:idle][name])) / (total - @prev[:total][name])}%"
        @prev[:idle][name] = idle
        @prev[:total][name] = total
      end
    }

    average = {'AVERAGE' => percents['AVERAGE']} and percents.delete('AVERAGE') and percents.merge!(average)
    self.datas = percents.to_a
  end

  def datas=(percs)
    @mutex.synchronize {
      @datas = []
      percs.each {|(name, perc)|
        @datas << {
          name:     name,
          percent:  perc
        }
      }
    }
  end
end

end

end
