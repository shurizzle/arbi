class File
  def self.each_line(*args, &blk)
    file = self.open(*args)
    file.each_line(&blk)
    file.close
  end
end

begin
  basedir = `pkg-config --variable=includedir x11`.strip
rescue
end

basedir = $?.exitstatus.zero? ? basedir : '/usr/include'
basedir = File.join(basedir, 'X11')
keysym = File.join(basedir, 'keysym.h')
keysymdef = File.join(basedir, 'keysymdef.h')
xf86keysym = File.join(basedir, 'XF86keysym.h')
output = File.open(File.join(File.dirname(__FILE__), '..', 'lib', 'arbi', 'server', 'keysyms.rb'), 'w+')

KEYSYM = {}
KEYSYMDEF = {}
enabled = true

File.each_line(keysym) {|line|
  if line.match(/^\s*#\s*define/)
    KEYSYM[line.match(/^\s*#\s*define\s+(\w+)/)[1]] = true
  end
}

output.print <<-EOF
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

module X11
  KEYSYM = {}
EOF

define_singleton_method(:parser) {|&blk|
  lambda {|line|
    if line.match(/^\s*#\s*ifdef/)
      enabled = KEYSYM[line.match(/^\s*#ifdef\s*(\w+)/)[1]]
      next
    end


    if line.match(/^\s*#\s*endif/)
      enabled = true
      next
    end

    next unless enabled

    if line.match(/^\s*#\s*define/)
      key, value = line.match(/^\s*#\s*define\s+(\w+)\s+(0x[0-9a-fA-F]+)/)[1..2] rescue next
      key = blk.(key)

        output.puts(line.match(/deprecated/i) ?
                    "# KEYSYM['#{key}'] = #{value} # deprecated" :
                    "  KEYSYM['#{key}'] = #{value}")
    end
  }
}

File.each_line(keysymdef, &parser {|key| key[3..-1] })
enabled = true
File.each_line(xf86keysym, &parser {|key| 'XF86' + key[7..-1] })

output.puts "end"
output.close
