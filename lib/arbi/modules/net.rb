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

require 'socket'

module Wireless
  def quality(ifname)
    File.read('/proc/net/wireless').match(/^\s*#{Regexp.escape(ifname)}:.*$/)[0].strip.split(/:?\s+/)[2].gsub('.', '') + "%"
  rescue
    nil
  end

  def self.essid (ifname)
    iwreq = [ifname, " " * 32, 32, 0].pack("a16pII")
    sock = ::Socket.new(:INET, :DGRAM, 0)
    sock.ioctl(0x8B1B, iwreq)
    return iwreq.unpack("a16pII")[1].strip
  rescue Exception => e
    Arbi.debug(e.backtrace[0] + ': ' + e.to_s + "\n" + e.backtrace[1..-1].join("\n"))
    nil
  end
end

module Arbi

module Modules

class Net < Arbi::Modules::Module
  def initialize(data = [])
    super(data)

    @mutex = Mutex.new
    @prev = {:up => {}, :down => {}}
    @datas = []

    every 1, :timeout => 10, &self.method(:update)
  end

  def valid?
    File.exist?('/proc/net/dev') and File.exist?('/proc/net/route') and
      File.exist?('/proc/net/wireless')
  end

  def refresh
    @mutex.synchronize {
      @data = @datas.dup
    }
  end

  def format
    tablize([['IFACE', 'UP', 'DOWN', 'STATE', 'QUALITY', 'ESSID']] + @data.map {|x|
      [x[:name] || x['name'], x[:up] || x['up'], x[:down] || x['down'],
        ((x[:state] || x['state']) ? 'on' : 'off'), x[:quality] || x['quality'],
        x[:essid] || x['essid']]
    })
  end

protected
  def update
    stats = {}
    File.read('/proc/net/dev').gsub(/^.*\|.*?\n/m, '').each_line {|line|
      name, *datas = line.strip.split(/:?\s+/)
      down = datas[0].to_i
       up  = datas[8].to_i

      @prev[:up][name] = @prev[:down][name] = 0 if !@prev[:up].include?(name) and !@prev[:down].include?(name)

      stats[name] = {
        up:       "%.1f kB/s" % [( up  - @prev[ :up ][name]).to_f / 1024],
        down:     "%.1f kB/s" % [(down - @prev[:down][name]).to_f / 1024],
        state:    (File.read('/proc/net/route') =~ /#{Regexp.escape(name)}/ ? true : false),
        quality:  nil,
        essid:    nil
      }

      if stats[name][:state]
        stats[name][:quality] = Wireless.quality(name)
        stats[name][ :essid ] = Wireless.essid(name) if stats[name][:quality]
      end

      @prev[ :up ][name] = up
      @prev[:down][name] = down
    }

    self.datas = stats
  rescue Exception => e
    Arbi.debug(e.to_s)
  end

  def datas=(stats)
    @mutex.synchronize {
      @datas = []
      stats.each {|(key, value)|
        value[:name] = key
        @datas << value
      }
    }
  end
end

end

end
