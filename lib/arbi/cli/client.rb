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
require 'arbi/client'
require 'arbi/config'
require 'arbi/version'

module Arbi

module Cli

class Client
  def initialize
    @address  = Arbi::Config[:client][:address]
    @port     = Arbi::Config[:client][:port]
    @commands = Arbi::Config[:client][:default_cmd]

    self.parse_args

    @client = Arbi::Client.new(@address, @port)

    @commands.each {|command|
      puts("#{command.upcase}:\n" + @client.get(command).format + "\n\n") if command !~ /^(quit|exit)$/i
    }
  rescue Errno::ECONNREFUSED
    puts "You have to start arbid daemon first, or specify a correct port."
    exit 1
  end

protected
  def parse_args
    OptionParser.new do |o|
      o.program_name  = 'arbi'
      o.banner        = "Arbi client v#{Arbi::VERSION}, USAGE:"

      o.on('-c', '--config CONF', 'Select configurations path, default to /etc/arbi.conf') do |conf|
        Arbi::Config.parse(conf)
      end

      o.on('-c', '--command COMMANDS', Array, 'Set commands to execute, default is \'help\'') do |cmd|
        cmd.delete('quit')
        @commands = (cmd & cmd).push('quit')
      end

      o.on('-a', '--address ADDR', 'Set address to connect, default to "127.0.0.1"') do |addr|
        @address = addr
      end

      o.on('-p', '--port PORT', 'Set port to connect, default to 6969') do |port|
        @port = port
      end

      o.on('-V', '--version', 'Print version and exit') do
        puts "Arbi client v#{Arbi::VERSION}"
        exit 0
      end

      o.on_tail('-h', '--help', 'Print this help and exit') do
        puts o.to_s
        exit 0
      end
    end.parse!
  rescue OptionParser::MissingArgument
    puts "At least one argument is required fro this option."
    puts "See help for details."
    exit 1
  end
end

end

end
