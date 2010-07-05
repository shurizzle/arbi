# encoding: utf-8

class Thermal
    require 'arbi/common'

    def initialize
        @temperatures = Hash.new
        @tempdirs = Dir.glob "/proc/acpi/thermal_zone/*"
        @tempdirs.each do |dir|
            trip_points = file_get_content dir + "/trip_points"
            name = dir.gsub(/^\/proc\/acpi\/thermal_zone\//, '')
            @temperatures.merge!({name => {'temperature' => file_get_content(dir + '/temperature').match(
                        /^temperature:\s*?([0-9]{1,3}) C$/)[1],
                    'trip_critical' => trip_points.match(/^critical \(S5\):\s*?([0-9]{1,3}) C$/)[1],}})
        end
    end

    def get_infos
        @tempdirs.each do |dir|
            @temperatures[dir.gsub(/^\/proc\/acpi\/thermal_zone\//, '')]["temperature"] =
                file_get_content(dir + '/temperature').match(/^temperature:\s*?([0-9]{1,3}) C$/)[1]
        end
        @temperatures.merge average
    end

    def average
        avg, n = 0, 0
        @temperatures.each do |value, key|
            avg += key["temperature"].to_i
            n += 1
        end
        avg = (sprintf '%.1f', (avg.to_f / n)).gsub /\.0$/, ''
        return ({'AVERAGE' => {'temperature' => avg, 'trip_critical' => false}})
    end

    def self.protocolize temperatures
        str = "thermal:\r\n"
        temperatures.each do |key, value|
            str += "#{key}|#{value["temperature"]}#{key == "AVERAGE" ? '' : '|' + (value["trip_critical"] || '-')}\r\n"
        end
        str += "END\r\n"
    end

    def self.friendlize raw
        raw = raw.to_s.strip
        nmax = raw.lines.map{|x|x.split(/\|/)[0].length}.max + 4
        tmax = [raw.lines.map{|x|x.split(/\|/)[1].length}.max + 4, 6].max
        str = "NAME".ljust(nmax) + "TEMP".ljust(tmax) + "CRITICAL\r\n"
        raw.split(/\r?\n/).each { |line|
            datas = line.split /\|/
            str << datas[0].ljust(nmax) + "#{datas[1]}°C".ljust(tmax)
            str << "#{datas[2]}°C" if datas[2]
            str << "\r\n"
        }
        str
    end
end

if __FILE__ == $0
    puts Thermal.friendlize Thermal.protocolize(Thermal.new.get_infos).gsub(/^thermal:\s+|END\s+$/m, '')
else
    Arbi::add_plugin /^thermal$/i, Thermal.new
end
