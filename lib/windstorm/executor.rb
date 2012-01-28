# coding: utf-8
require 'yaml'

module Windstorm
  module Reader

    private

    def read(file)
      raise 'file not found' unless (File.exist?(file) && File.file?(file))
      File.read(file)
    end

    def yaml_read(file)
      YAML.load(read(file))
    end
  end

  class Executor
    include Reader

    attr_writer :parser

    class << self
      include Reader

      def create_from_file(file)
        create_from_table(yaml_read(file))
      end

      def create_from_table(t)
        create(Parser.create(t))
      end

      def create(pa)
        return unless pa
        ex = self.new
        ex.parser = pa
        ex
      end

    end

    def parser
      raise 'parser not found' unless @parser
      @parser
    end

    def machine
      raise 'not executed yet' unless @machine
      @machine
    end

    def execute(source, params = nil)
      @machine = Machine.create(parser.build(source), params)
      @machine.execute
    end

    def execute_from_file(file, params = nil)
      execute(read(file), params)
    end

    def filter(source)
      parser.filter(source)
    end

    def filter_from_file(file)
      filter(read(file))
    end

    def build(source)
      parser.build(source)
    end

    def build_from_file(file)
      build(read(file))
    end

    def debug_execute(source, params = nil)
      execute(source, {:debug => true}.merge(params || {}))
    end

    def debug_execute_from_file(file, params = nil)
      debug_execute(read(file), params)
    end

  end
end
