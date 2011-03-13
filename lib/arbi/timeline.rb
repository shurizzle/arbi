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

require 'eventmachine'
require 'timeout'

module TimeLine
  class Job
    attr_reader :every, :timeout, :proc

    def initialize(ev = 2, to = 5, &blk)
      self.every = ev
      self.timeout = to
      self.proc = blk

      TimeLine.register(self)
    end

    def every=(ev)
      raise ArgumentError, "every must be an Integer > 0" unless ev.is_a?(Integer) and ev > 0
      @every = ev
    end

    def timeout=(to)
      raise ArgumentError, "timeout must be an Integer > 0" unless to.is_a?(Integer) and to > 0
      @timeout = to
    end

    def proc=(blk)
      raise ArgumentError, "proc must be a Proc" unless blk.is_a?(Proc)
      @proc = blk
    end
  end

  class << self
    def register(job)
      raise ArgumentError, "job must be a TimeLine::Job" unless job.is_a?(TimeLine::Job)
      @@jobs ||= []
      @@jobs << job
    end

    def run
      @@jobs ||= []
      @@jobs.each {|job|
        EventMachine::PeriodicTimer.new(job.every) do
          timeout(job.timeout) {
            job.proc.call
          }
        end
      }
      self
    end
  end
end
