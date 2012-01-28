# coding: utf-8
module Windstorm
  class Parser

    class << self

      def create(t)
        ps = self.new
        ps.table = t
        ps
      end

    end

    def table=(t)
      raise 'definition blank' if t.nil? || t.empty?
      @table = {}
      COMMANDS.each do |c|
        li = [t[c]].flatten.compact.uniq
        next if li.empty?
        @table[c] = li
      end
      raise 'definition not found' if @table.empty?
      @dict = nil
      @table
    end

    def table
      raise 'definition not found' if @table.nil? || @table.empty?
      @table
    end

    def dict
      @dict ||= lambda do
        dic = {}
        table.each do |c, s|
          [s].flatten.each{|t| dic[t] = c}
        end
        dic
      end.call
      @dict
    end

    def filter(source)
      return [] unless source
      reg = /#{dict.keys.map{|k| Regexp.escape(k)}.join('|')}/
      ret = []
      source.lines do |l|
        next if l.start_with?('#') || l.start_with?('//')
        ret << l.scan(reg).flatten
      end
      ret.flatten
    end

    def convert(fs)
      [fs].flatten.map{|s| dict[s]}.compact
    end

    def build(source)
      convert(filter(source))
    end

  end
end
