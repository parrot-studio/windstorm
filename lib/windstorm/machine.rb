# coding: utf-8
module Windstorm
  class Machine

    attr_writer :commands, :size, :debug, :flash, :loose

    class << self

      def create(coms, params = nil)
        params ||= {}
        s = params[:size].to_i

        m = self.new
        m.commands = coms
        m.size = s if s > 0
        m.debug = true if params[:debug]
        m.flash = true if params[:flash]
        m.loose = true if params[:loose]
        m
      end

      def execute(coms, params = nil)
        m = create(coms, params)
        m.execute
      end

    end

    def execute
      return result if finish?
      parse_jump
      loop do
        break if finish?
        step_execute
      end
      result
    end

    def step_execute
      case com
      when :pinc
        move_point_inc
      when :pdec
        move_point_dec
      when :inc
        increment
      when :dec
        decrement
      when :out
        output
      when :inp
        input
      when :jmp
        jump if value == 0
      when :ret
        jump unless value == 0
      when :clip
        clip
      when :paste
        paste
      end
      debug_out if debug?
      forward
      self
    end

    def debug?
      @debug ? true : false
    end

    def loose?
      @loose ? true : false
    end

    def strict?
      ! loose?
    end

    def step
      @step ||= 0
      @step
    end

    def add_step
      @step = step + 1
      step
    end

    def commands
      @commands ||= []
      @commands
    end

    def index
      @index ||= 0
      @index
    end

    def add_index
      @index = index + 1
      @index
    end

    def com(ind = nil)
      ind ||= index
      commands[ind]
    end

    def forward
      add_step
      add_index
      self
    end

    def finish?
      index >= commands.size ? true : false
    end

    def jump_table
      @jump_table ||= {}
      @jump_table
    end

    def parse_jump
      return if commands.empty?
      inds = []
      commands.each.with_index do |com, i|
        case com
        when :jmp
          inds << i
        when :ret
          hind = inds.delete_at(-1)
          raise 'jump couples invalid' unless hind
          jump_table[hind] = i
          jump_table[i] = hind
        end
      end
      raise 'jump couples invalid' unless inds.empty?
      if debug? && !jump_table.empty?
        puts 'jump table:'
        puts jump_table
      end
      self
    end

    def jump_index(ind)
      error 'jump index is nil' unless ind
      strict_error 'out of command index' if ind < 0 || ind >= commands.size
      @index = ind
    end

    def jump
      jump_index(jump_table[index])
    end

    def size
      @size ||= BUFFER_DEFAULT_SIZE
      @size = BUFFER_DEFAULT_SIZE if @size <= 0
      @size
    end

    def point
      @point ||= 0
      strict_error 'point over' if (@point < 0 || @point >= size)
      @point
    end

    def move_point_inc
      @point = point + 1
      point
    end

    def move_point_dec
      @point = point - 1
      point
    end

    def increment
      replace_value(value+1)
    end

    def decrement
      replace_value(value-1)
    end

    def buffer
      @buffer ||= []
      @buffer
    end

    def value(po = nil)
      po ||= point
      strict_error 'point over' if (po < 0 || po >= size)
      buffer[po] || 0
    end

    def replace_value(val, po = nil)
      po ||= point
      strict_error 'value under 0' if val < 0
      strict_error 'point over' if (po < 0 || po >= size)
      buffer[po] = val
    end

    def cache
      @cache ||= ""
      @cache
    end
    alias :result :cache

    def output
      putc value if @flash
      cache << value.chr
    end

    def input
      c = $stdin.getc
      replace_value(c.bytes.first)
    end

    def clip_value
      @clip_value ||= 0
      @clip_value
    end

    def replace_clip_value(val)
      strict_error 'value under 0' if val < 0
      @clip_value = val
    end

    def clip
      replace_clip_value(value)
    end

    def paste
      replace_value(clip_value)
    end

    def debug_out
      puts "step:#{step} com:#{com} index:#{index} point:#{point} buffer:#{buffer.inspect} clip:#{clip_value} result:#{result}"
    end

    private

    def error(msg)
      raise msg
    end

    def strict_error(msg)
      return unless strict?
      error(msg)
    end

  end
end
