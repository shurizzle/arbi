#!/usr/bin/ruby

class Regexp
    alias oldto_s to_s
    def to_s
        regex = oldto_s.gsub(/^\(\?|\)/, '')
        "/#{regex.split(/:/, 2)[1]}/#{regex.split(':')[0].split('-')[0]}"
    end
end

module Arbi

    require 'getopt/long'
    include Getopt

    VERSION = "1.0.2"

    @cmd = []

    def self.add_plugin regex, instance
        @cmd += [[regex, instance]]
    end

    def self.cmd
        @cmd
    end

    def self.show_version
        puts "Arbi (Client|Server) v#{VERSION}"
        exit 0
    end

    class Server
        require 'socket'

        def initialize
            @threads = Array.new
            @sessions = Array.new
            @address = 'localhost'
            @port = 6969
            parse_args
            @server = TCPServer.new(@address, @port)
        end

        def show_help
            puts "Arbi Server, USAGE:"
            puts "\t#{$0} [switches]"
            puts "\t\t--bind-address|-a\tAddress to bind, default to \"127.0.0.1\""
            puts "\t\t        --port|-p\tPort to use for server, default to 40"
            puts "\t\t     --version|-v\tPrint version and exit"
            puts "\t\t        --help|-h\tPrint this help and exit"
            exit 0
        end

        def start
            @servert = Thread.new do
                while(session = @server.accept)
                    new_client session
                end
            end
            @servert.join
        end

        def close
            @sessions.each{ |session|
                session.close
            }

            @threads.each{ |thread|
                thread.kill
            }
            @server.close
            @servert.kill
        end

    private

        def parse_args
            begin
                opts = Arbi::Long.getopts(
                    ["--bind-address", "-a", Arbi::REQUIRED],
                    ["--port", "-p", Arbi::REQUIRED],
                    ["--help", "-h", Arbi::BOOLEAN],
                    ["--version", "-v", Arbi::BOOLEAN]
                )
            rescue Getopt::Long::Error => e
                puts "Arguments error: #{e}"
                exit 0
            end

            @address = opts['a']    if opts['a']
            @port    = opts['p']    if opts['p']
            show_help               if opts['h']
            Arbi::show_version      if opts['v']
        end

        def new_client session
            @threads.push Thread.start(session){ |session|
                while message = session.gets
                    toggle = true
                    message = message.strip
                    break if message =~ /^QUIT$/i

                    if message =~ /^HELP$/i
                        session.print "help:\r\n"
                        Arbi::cmd.each { |pair|
                            session.print "#{pair[0]}\r\n"
                        }
                        session.print "/^quit$/i\r\n"
                        session.print "/^version$/i\r\n"
                        session.print "/^help$/i\r\n"
                        session.print "END\r\n"
                        toggle = !toggle
                    end

                    if message =~ /^VERSION$/i
                        session.print "version:\r\nArbi (Client|Server) v#{VERSION}\r\nEND\r\n"
                        toggle = !toggle
                    end

                    Arbi::cmd.each { |pair|
                        if message =~ pair[0]
                            session.print (pair[1].class == Class ? pair[1].protocolize(pair[1].get_infos) : pair[1].class.protocolize(pair[1].get_infos))
                            toggle = !toggle
                        end
                    }
                    session.print "error:\r\nCommand doesn't exist\r\nEND\r\n" if toggle
                end
                @sessions -= [session]
                session.close
            }
            @sessions.push session
        end
    end

    class Client
        def initialize
            @address = 'localhost'
            @port = 6969
            @command = "help\r\nquit\r\n"
            parse_args
            @sock = TCPSocket.new(@address, @port)
        end

        def start
            @sock.print @command
            @command = @command.strip.split(/\r\n/).map(&:upcase)
            @command.pop
            toggle = false
            while (line = @sock.gets)
                puts (command = @command.shift) + ":"
                buff = ""
                while (l = @sock.gets).strip !~ /^END$/i do; buff << l; end
                buff.gsub!(/END\s+$/m, '')
                case line.strip
                when /^error:$/i
                    puts "ERROR: #{buff}"
                    next
                when /^help:$/i
                    puts buff
                when /^version$:/i
                    puts buff
                end
                Arbi::cmd.each{|cmd|
                    puts (cmd[1].class == Class ? cmd[1].friendlize(buff) : cmd[1].class.friendlize(buff)) if command =~ cmd[0]
                }
                puts if @command != []
            end
        end

        def close
            @sock.close
        end

        def show_help
            puts "Arbi client:"
            puts "\tUSAGE: #{$0} [switches]"
            puts "\t\t   --help|-h\tshow this helps"
            puts "\t\t--version|-v\tshow version of arbi"
            puts "\t\t--address|-a\tset the address to connect, default to 'localhost'"
            puts "\t\t   --port|-p\tset the port to connect, default to 40"
            puts "\t\t--command|-c\tset commands to execute, defaults is 'help'"
            exit 0
        end

    private

        def parse_args
            begin
                opts = Arbi::Long.getopts(
                    ["--help"],
                    ["--version"],
                    ["--address", "-a", Arbi::REQUIRED],
                    ["--port", "-p", Arbi::REQUIRED],
                    ["--commands", "-c", Arbi::REQUIRED]
                )
            rescue Arbi::Long::Error => e
                p ARGV
                $stderr.puts "Arguments error: #{e}"
                exit 1
            end

            Arbi::show_version      if opts["v"]
            show_help               if opts["h"]
            @address    = opts["a"] if opts["a"]
            @port       = opts["p"] if opts["p"]
            @command    = "#{opts["c"]},quit".gsub(/,+/, ',').gsub(/\s+/, '').split(/,/).
                delete_if{|x|x=~/^quit$/i}.uniq.push('quit', '').join("\r\n") if opts["c"]
        end
    end
end

require 'arbi/plugins/batteries'
require 'arbi/plugins/cpu'
require 'arbi/plugins/diskspace'
require 'arbi/plugins/net'
require 'arbi/plugins/ram'
require 'arbi/plugins/thermal'
