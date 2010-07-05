class Diskspace
    require 'arbi/common'
    require 'sys/filesystem'
    include Sys

    def get_infos
        devices = Array.new
        get_devices.each do |device|
            begin
                diskstat = Filesystem.stat device['point']
                device.merge!({'usage' => (100 - (100.0 / diskstat.blocks  * diskstat.blocks_available).round).to_s + "%",
                    'space' => diskstat.blocks * diskstat.fragment_size})
                devices += [device]
            rescue
            end
        end
        devices
    end

    def get_devices
        devices = Array.new
        Filesystem.mounts do |fs|
                devices += [{'device' => fs.name, 'point' => fs.mount_point}]
        end
        devices
    end

    def self.unitize misure
        u = 'b'
        %w(Kb Mb Gb Tb).each do |i|
            if misure >= 1024
                misure /= 1024.0
                u = i
            else
                return misure.round.to_s + u
            end
        end
        misure.round.to_s + u
    end

    def self.protocolize devices
        str = "devices:\r\n"
        devices.each do |device|
            str += "#{device['device']}|#{device['point']}|#{device['usage']}|#{self.unitize device['space']}\r\n"
        end
        str + "END\r\n"
    end

    def self.friendlize raw
        raw = raw.to_s.strip
        dmax = [raw.lines.map{|line|line.split(/\|/)[0].length}.max + 4, 8].max
        mmax = [raw.lines.map{|line|line.split(/\|/)[1].length}.max + 4, 7].max
        str = "DEVICE".ljust(dmax) + "MOUNT".ljust(mmax) + "USE %  SPACE\r\n"
        raw.split(/\r?\n/).each { |line|
            datas = line.split /\|/
            str << datas[0].ljust(dmax) + datas[1].ljust(mmax) + datas[2].ljust(7) + datas[3] + "\r\n"
        }
        str
    end
end

if __FILE__ == $0
    puts Diskspace.friendlize Diskspace.protocolize(Diskspace.new.get_infos).gsub(/^devices:\s+|END\s+$/m, '')
else
    Arbi::add_plugin /^diskstats$/i, Diskspace.new
end
