#!/usr/bin/env ruby
#
# $Id$
#
# This script lists each exploit module by its compatible payloads
#
# $Revision$
#

msfbase = __FILE__
while File.symlink?(msfbase)
  msfbase = File.expand_path(File.readlink(msfbase), File.dirname(msfbase))
end

$:.unshift(File.expand_path(File.join(File.dirname(msfbase), '..', 'lib')))
require 'msfenv'

$:.unshift(ENV['MSF_LOCAL_LIB']) if ENV['MSF_LOCAL_LIB']

require 'rex'
require 'msf/ui'
require 'msf/base'


def print_status(msg)
  print_line "[*] #{msg}"
end

def print_error(msg)
  print_line "[-] #{msg}"
end

def print_line(msg)
  $stderr.puts msg
end

def is_dynamic_size?(mod)
  [*(1..5)].map{|x| mod.new.size}.uniq.length != 1
end

def update_cache_size(mod)
  data = ''
  File.open(mod.file_path, 'rb'){|fd| data = fd.read(fd.stat.size)}
  data = data.gsub(/^\s*CachedSize\s*=\s*\d+.*/, '')
  data = data.gsub(/^(module Metasploit\d+)/) {|m| "#{m}\n  CachedSize = #{mod.new.size}\n" }
  File.open(mod.file_path, 'wb'){|fd| fd.write(data) }
end

# Initialize the simplified framework instance.
$framework = Msf::Simple::Framework.create('DisableDatabase' => true)

$framework.payloads.each_module do |name, mod|
  gsize = mod.new.size

  if is_dynamic_size?(mod)
    print_status("#{mod.file_path} has a dynamic size, skipping...")
    next
  end

  if mod.cached_size.nil?
    print_status("#{mod.file_path} has size #{gsize}, updating cache...")
    update_cache_size(mod)
  else
    next if gsize == mod.cached_size
    print_error("#{mod.file_path} has cached size #{mod.cached_size} but generated #{gsize}")
    update_cache_size(mod)
    next
  end
end
