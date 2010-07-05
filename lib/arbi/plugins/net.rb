class Net
    require 'arbi/common'
    require 'thread'

    def initialize
        @stats = Hash.new
        @prev = {:up => Hash.new, :down => Hash.new}
        @mutex = Mutex.new
        @serv = Thread.new do
            while true
                @mutex.lock
                update
                @mutex.unlock
                sleep 2
            end
        end
    end

    def update
        file_get_content('/proc/net/dev').gsub(/^.*\|.*?\n/m, '').split("\n").each do |line|
            datas = line.gsub(/^\s+|\s+$/, '').split(/:\s+|\s+/)
            name = datas.shift
            down = datas[0].to_i
            up = datas[8].to_i

            if not @prev[:up].include? name or not @prev[:down].include? name
                @prev[:up][name] = @prev[:down][name] = 0
            end
            
            @stats[name] = {:up => (up - @prev[:up][name]) / 1024.0,
                :down => (down - @prev[:down][name]) / 1024.0,
                :state => get_state(name),
                :quality => nil,
                :essid => nil}
            if @stats[name][:state]
                @stats[name][:quality] = get_quality(name)
                @stats[name][:essid] = get_essid(name) if @stats[name][:quality]
            end
            @prev[:up][name] = up
            @prev[:down][name]  = down
        end
    end

    def get_infos
        @mutex.lock
        s = @stats
        @mutex.unlock
        s
    end

    def self.protocolize stats
        str = "net:\r\n"
        stats.each { |key, value|
            str += "#{key}|#{value[:up]}|#{value[:down]}|#{value[:state] ? 'on' : 'off'}"
            if value[:quality]
                str += "|#{value[:essid]}|#{value[:quality]}"
            end
            str += "\r\n"
        }
        str + "END\r\n"
    end

    def get_state interface
        if file_get_content('/proc/net/route') =~ /#{interface}/
            true
        else
            false
        end
    end

    def get_quality interface
        begin
            file_get_content('/proc/net/wireless').match(/^\s*?#{interface}:.*$/)[0].strip.split(/:\s+|\s+/)[2].gsub('.', '') + "%"
        rescue
            nil
        end
    end

    def get_essid interface
        require "socket"

        iwreq = [interface, " " * 32, 32, 0].pack("a16pII")
        sock = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, 0)
        sock.ioctl(0x8B1B, iwreq)
        return iwreq.unpack("a16pII")[1].strip
    end

    def self.friendlize raw
        raw = raw.to_s.strip
        nmax = raw.lines.map{|x|x.split(/\|/)[0].length}.max + 4
        umax = raw.lines.map{|x|x.split(/\|/)[1].gsub(/^(\d+\.\d).*$/, '\1').length}.max + 2
        dmax = raw.lines.map{|x|x.split(/\|/)[2].gsub(/^(\d+\.\d).*$/, '\1').length}.max + 2
        emax = [[raw.lines.map{|x|x.split(/\|/)[4].to_s.length}.max + 4, 7].max, 34].min
        str = "NAME".ljust(nmax) + "UP      DOWN    STATE  " + "ESSID".ljust(emax) + "QUALITY\r\n"
        raw.split(/\r?\n/).each { |line|
            datas = line.split(/\|/)
            str << datas[0].ljust(nmax) + ('%.1f' % datas[1].to_f).ljust(8) + ('%.1f' % datas[2].to_f).ljust(8) + datas[3].ljust(7)
            str << datas[4].ljust(emax) + datas[5] if datas[4]
            str << "\r\n"
        }
        str
    end

    def close
        @serv.kill
    end
end

if __FILE__ == $0
    x = Net.new
    10.times {
        sleep 2
        puts Net.friendlize Net.protocolize(x.get_infos).gsub(/^net:\s+|END\s+$/m, '')
    }
    x.close
else
    Arbi::add_plugin /^net$/i, Net.new
end
