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

require 'ffi'
require_relative './keysyms'

module X11
  extend FFI::Library

  ffi_lib 'X11', 'Xtst'

  class XkbModsRec < FFI::Struct
    layout :mask, :uchar,
      :real_mods, :uchar,
      :vmods, :ushort
  end

  class XkbControlsRec < FFI::Struct
    layout :mk_dflt_btn, :uchar,
      :num_groups, :uchar,
      :groups_wrap, :uchar,
      :internal, XkbModsRec,
      :ignore_lock, XkbModsRec,
      :enabled_ctrls, :uint,
      :repeat_delay, :ushort,
      :repeat_interval, :ushort,
      :slow_keys_delay, :ushort,
      :debounce_delay, :ushort,
      :mk_delay, :ushort,
      :mk_interval, :ushort,
      :mk_time_to_max, :ushort,
      :mk_max_speed, :ushort,
      :mk_curve, :short,
      :ax_options, :ushort,
      :ax_timeout, :ushort,
      :axt_opts_mask, :ushort,
      :axt_opts_values, :ushort,
      :axt_ctrls_mask, :uint,
      :axt_ctrls_values, :uint,
      :per_key_repeat, [:uchar, 32]
  end

  class XkbDescRec < FFI::Struct
    layout :dpy, :pointer,
      :flags, :ushort,
      :device_spec, :ushort,
      :min_key_code, :uchar,
      :max_key_code, :uchar,
      :ctrls, :pointer,
      :server, :pointer,
      :map, :pointer,
      :indicators, :pointer,
      :names, :pointer,
      :compat, :pointer,
      :geom, :pointer
  end

  attach_function :XKeysymToKeycode, [:pointer, :ulong], :uchar
  attach_function :XTestGrabControl, [:pointer, :bool], :int
  attach_function :XTestFakeKeyEvent, [:pointer, :uint, :bool, :ulong], :int
  attach_function :XSync, [:pointer, :bool], :int
  attach_function :XOpenDisplay, [:pointer], :pointer
  attach_function :XkbAllocKeyboard, [], :pointer
  attach_function :XkbGetControls, [:pointer, :ulong, :pointer], :int

  def self.delay
    return [] if (dpy = X11.XOpenDisplay(nil)).null?
    xkb = X11.XkbAllocKeyboard
    X11.XkbGetControls(dpy, 1, xkb)
    res = X11::XkbControlsRec.new(X11::XkbDescRec.new(xkb)[:ctrls])
    [res[:repeat_delay], (1000 / res[:repeat_interval])]
  end

  class Key
    def initialize(disp = X11.XOpenDisplay(nil), keysym, modsym)
      return if !disp or disp.null?
      @disp = disp
      @keycode = X11.XKeysymToKeycode(@disp, keysym || 0)
      @modcode = modsym && modsym.zero? ? 0 : X11.XKeysymToKeycode(disp, modsym || 0)
    end

    def press
      action { shot }
    end

    def release
      action { shot false }
    end

    def self.parse(str)
      *mods, key = str.split(?-).map {|mod|
        X11::KEYSYM[mod]
      }.compact

      mod = mods.inject(:|)

      self.new(key, mod)
    end

  protected
    def action
      return self if !@disp or @keycode.zero? or !block_given?
      X11.XTestGrabControl(@disp, true)
      yield
      X11.XSync(@disp, false)
      X11.XTestGrabControl(@disp, false)
      self
    end

    def shot(bool = true)
      X11.XTestFakeKeyEvent(@disp, @modcode, bool, 0) if @modcode != 0 and bool
      X11.XTestFakeKeyEvent(@disp, @keycode, bool, 0)
      X11.XTestFakeKeyEvent(@disp, @modcode, bool, 0) if @modcode != 0 and !bool
    end
  end

  class OneShotKey < Key
    def press
      action {
        [true, false].each {|bool|
          shot bool
        }
      }
    end

    undef_method :release
  end
end
