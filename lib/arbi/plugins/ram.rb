class Ram
    require 'arbi/common'

    def get_infos
        mem = file_get_content('/proc/meminfo')
        total = mem.match(/^MemTotal:\s*?([0-9]+) kB/)[1].to_i
        free = mem.match(/^MemFree:\s*?([0-9]+) kB/)[1].to_i +
            mem.match(/^Buffers:\s*?([0-9]+) kB/)[1].to_i +
            mem.match(/^Cached:\s*?([0-9]+) kB/)[1].to_i
        perc = 100.0 / total * free
        {'used' => sprintf('%.1f%%', 100.0 - perc),
            'free' => sprintf('%.1f%%', perc)}
    end

    def self.protocolize perc
        "ram:\r\n#{perc['used']}|#{perc['free']}\r\nEND\r\n"
    end

    def self.friendlize raw
        datas = raw.to_s.strip.split(/\r?\n/)[0].split(/\|/)
        "USED    FREE\r\n#{datas[0].ljust(8)}#{datas[1]}"
    end
end

if __FILE__ == $0
    puts Ram.friendlize Ram.protocolize(Ram.new.get_infos).gsub(/^ram:\s+|END\s+$/m, '')
else
    Arbi::add_plugin /^ram$/i, Ram.new
end
