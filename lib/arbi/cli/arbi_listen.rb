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

require 'optparse'
require 'arbi/server'
require 'arbi/version'

module Arbi

module Cli

class ArbiListen
  def initialize
    self.parse_args

    @address ||= Arbi::Config[:server][:acpi][:bind]

    Arbi::Config[:server][:acpi][:listen] = @address

    EventMachine.run {
      Arbi::Server::Acpi::EventListener.new(STDOUT)
    }
  end

protected
  def parse_args
    OptionParser.new do |o|
      o.program_name  = 'arbid'
      o.banner        = "Arbi server listener v#{Arbi::VERSION}, USAGE:"

      o.on('-C', '--config CONF', 'Select configurations path, default to /etc/arbi.conf') do |conf|
        Arbi::Config.parse(conf)
      end

      o.on('-s', '--socket PATH', 'UNIX to listen from') do |addr|
        @address = addr
      end

      o.on('-V', '--version', 'Print version and exit') do
        puts "Arbi server v#{Arbi::VERSION}"
        exit 0
      end

      o.on_tail('-h', '--help', 'Print this help and exit') do
        puts o.to_s
        exit 0
      end
    end.parse!
  rescue OptionParser::MissingArgument
    puts "At least one argument is required for this option."
    puts "See help for detail"
    exit 1
  end
end

end

end
