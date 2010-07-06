class Cpu
    require 'arbi/common'
    require 'thread'

    def initialize
        @prev = {:idle => Hash.new, :total => Hash.new}
        @percents = Hash.new
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

    def get_infos
        @mutex.lock
        perc = @percents
        @mutex.unlock
        perc
    end

    def self.protocolize percents
        str = "cpu:\r\n"
        percents.each { |key, value|
            str += "#{key}|#{value}\r\n"
        }
        str + "END\r\n"
    end

    def self.friendlize raw
        raw = raw.to_s.strip
        max = raw.lines.map{|x|x.split(/\|/)[0].length}.max + 4
        str = "NAME".ljust(max) + "PERC\r\n"
        raw.split(/\r?\n/).each { |line|
            datas = line.split /\|/
            str << datas[0].ljust(max) + datas[1] + "\r\n"
        }
        str
    end

    def close
        @serv.kill
    end

private

    def update
        file_get_content('/proc/stat').split("\n").each do |line|
            if line =~ /^cpu/
                datas = line.split /\s+/
                name = datas.shift
                name = (name == 'cpu' ? 'AVERAGE' : name)
                total = eval datas.join('+')
                idle = datas[3].to_i

                if not @prev[:idle].include? name or not @prev[:total].include? name
                    @prev[:idle][name] = @prev[:total][name] = 0
                end

                @percents[name] = (100 * ((total - @prev[:total][name]) - (idle - @prev[:idle][name])) / (total - @prev[:total][name])).to_s + "%"
                @prev[:idle][name] = idle
                @prev[:total][name] = total
            end
        end
        
        average = {"AVERAGE" => @percents["AVERAGE"]} and @percents.delete("AVERAGE") and @percents.merge!(average)
    end
end

if __FILE__ == $0
    x = Cpu.new
    ["INT", "KILL", "ABRT", "ILL", "QUIT"].each do |sig|
        trap(sig) do
            x.close
            exit 0
        end
    end
    10.times {
        sleep 2
        puts Cpu.friendlize Cpu.protocolize(x.get_infos).gsub(/^cpu:\s+|END\s+/m, '')
    }
    x.close
else
    Arbi.add_plugin /^cpu$/i, Cpu.new
end
