class Batteries
    require 'arbi/common'

    def initialize
        @AC = {'sanity' => false, 'state' => false, 'percent' => false}
        @batteries = Dir.glob "/proc/acpi/battery/*"
    end

    def get_infos
        batteries = Hash.new
        @batteries.each { |battery|
            batteries.merge!(get_battery_infos(battery))
        }
        batteries.merge average batteries
    end

    def average batteries
        avg, n = 0, 0
        batteries.each do |key, value|
            if value["percent"]
                avg += value["percent"].gsub(/%$/, '').to_i
                n += 1
            end
        end
        avg = (avg.to_f / n).to_s.gsub /\.0/, '' + '%'

        ({'AVERAGE' => {
            'sanity'    => '-',
            'state'     => '-',
            'percent'   => avg
            }
        })
    end

    def get_battery_infos dir
        info = file_get_content dir + "/info"
        state = file_get_content dir + "/state"
        present = {'yes' => true, 'no' => false}[state.match(/^present:\s*?([^\s]+?)$/)[1]]
        if !present then return {dir.gsub(/^\/proc\/acpi\/battery\//, '') => @AC} end
        ({dir.gsub(/^\/proc\/acpi\/battery\//, '') => {
            'sanity'    => sprintf('%.1f%%', 100.0 /
                    (info.match(/^design capacity:\s*?([^\s]+?) mAh$/)[1].to_i) *
                    (info.match(/^last full capacity:\s*?([^\s]+?) mAh$/)[1].to_i)).gsub(/\.0%$/, '%'),
            'state'     => state.match(/^charging state:\s*?([^\s]+?)$/)[1],
            'percent'   => sprintf('%.1f%%', 100.0 /
                    (info.match(/^last full capacity:\s*?([^\s]+?) mAh$/)[1].to_i) *
                    (state.match(/^remaining capacity:\s*?([^\s]+?) mAh$/)[1].to_i)).gsub(/\.0%$/, '%')
        }})
    end

    def self.protocolize batteries
        str = "batteries:\r\n"
        batteries.each { |key, value|
            str << "#{key}|#{value["percent"] || '-'}"
            if key != "AVERAGE"
                str << "|#{value["state"] || '-'}|#{value["sanity"] || '-'}"
            end
            str << "\r\n"
        }
        str << "END\r\n"
    end

    def self.friendlize raw
        raw.strip!
        max = raw.lines.map{|x| x.split(/\|/)[0].length}.max + 4
        str = "NAME".ljust(max) + "PERC    STATE       SANITY\r\n"
        raw.split(/\r?\n/).each { |line|
            datas = line.split /\|/
            str << datas[0].ljust(max) + datas[1].ljust(8)
            if datas[0] != "AVERAGE"
                str << datas[2].ljust(12) + datas[3]
            end
            str << "\r\n"
        }
        str
    end
end

if __FILE__ == $0
    puts Batteries.friendlize Batteries.protocolize(Batteries.new.get_infos).gsub(/^batteries:\s+|^END\s+/m, '').strip
else
    Arbi.add_plugin /^batteries$/i, Batteries.new
end
