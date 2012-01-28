# coding: utf-8
module Windstorm

  BUFFER_DEFAULT_SIZE = 100
  COMMANDS = [:pinc, :pdec, :inc, :dec, :out, :inp, :jmp, :ret, :clip, :paste]

end

path = File.join(File.dirname(__FILE__), 'windstorm')
require File.join(path, 'parser')
require File.join(path, 'machine')
require File.join(path, 'executor')
