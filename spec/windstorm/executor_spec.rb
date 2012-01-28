# coding: utf-8
require 'spec_helper'

FIXTURES_PATH = File.join(File.dirname(__FILE__), '..', 'fixtures')

def file_from_fixtures(file)
  File.join(FIXTURES_PATH, file)
end

describe Windstorm::Executor do

  describe '.create' do
    context 'with parser' do
      before do
        @table = {:inc => ['a', 'z'], :dec => ['b']}
        @parser = Parser.create(@table)
      end

      subject { Executor.create(@parser) }

      its(:parser){ should == @parser }
      it { subject.parser.table.should == @table }
    end

    context 'given nil' do
      it { Executor.create(nil).should be_nil }
    end
  end

  describe '.create_from_table' do
    context 'with table' do
      before { @table = {:inc => ['a', 'z'], :dec => ['b']} }
      subject { Executor.create_from_table(@table) }
      it { subject.parser.table.should == @table }
    end

    context 'invalid table' do
      before { @table = {:hoge => 'a'} }
      it { lambda{ Executor.create_from_table(@table) }.should raise_error }
    end

    context 'given nil' do
      it { lambda{ Executor.create_from_table(nil) }.should raise_error }
    end
  end

  describe '.create_from_file' do
    context 'with file' do
      before do
        @file = file_from_fixtures('bf.yml')
        @expect = YAML.load(File.read(@file))
      end

      subject { Executor.create_from_file(@file) }
      it { subject.parser.table.should == @expect }
    end

    context 'file not found' do
      it { lambda{ Executor.create_from_file('hogepiyo') }.should raise_error }
    end

    context 'invalid definition' do
      it { lambda{ Executor.create_from_file(file_from_fixtures('invalid.yml')) }.should raise_error }
    end
  end

  describe '#parser' do
    context 'parser not seted' do
      it { lambda{ Executor.new.parser }.should raise_error }
    end
  end

  describe 'instance method' do
    before do
      @exec = Executor.create_from_file(file_from_fixtures('bf.yml'))
      @source_file = file_from_fixtures('source.txt')
    end

    describe '#filter' do
      it { @exec.filter('steins gate').should == ['e', 'i', 'g', 'a', 'e'] }
    end

    describe '#filter_from_file' do
      it { @exec.filter_from_file(@source_file).should_not be_empty }
    end

    describe '#build' do
      it { @exec.build('steins gate').should == [:out, :clip, :jmp, :pinc, :out] }
    end

    describe '#build_from_file' do
      it { @exec.build_from_file(@source_file).should_not be_empty }
    end

    describe 'each execute method' do
      before do
        @out = StringIO.new
        @org_out = $stdout
        $stdout = @out

        @source = @exec.filter_from_file(@source_file).join('')
      end

      describe '#execute' do
        context 'non params' do
          it { @exec.execute(@source).should == 'end' }
        end

        context 'with params' do
          before { @exec.execute(@source, :flash => true) }
          it { @out.string.should == 'end' }
        end
      end

      describe '#execute_from_file' do
        context 'non params' do
          it { @exec.execute_from_file(@source_file).should == 'end' }
        end

        context 'with params' do
          before { @exec.execute_from_file(@source_file, :flash => true) }
          it { @out.string.should == 'end' }
        end
      end

      describe '#machine' do
        context 'not executed yet' do
          it { lambda{ @exec.machine }.should raise_error }
        end

        context 'executed machine' do
          before { @exec.execute(@source) }
          subject{ @exec.machine }
          it { should be_instance_of(Machine) }
          its(:result){ should == 'end' }
        end
      end

      describe '#debug_execute' do
        context 'non params' do
          before do
            @result = @exec.debug_execute(@source)
            @lines = @out.string.each_line.to_a
            @jump = @lines.delete_at(0) # "jump table"
            @lines.shift # jump table data
          end
          it { @result.should == 'end' }
          it { @jump.should match(/\Ajump/) }
          it 'only debug outout in normal-mode' do
            @lines.all?{|l| l.match(/\Astep:/)}.should be_true
          end
        end

        context 'with params' do
          before do
            @result = @exec.debug_execute(@source, :flash => true)
            @lines = @out.string.each_line.to_a
            @jump = @lines.delete_at(0) # "jump table"
            @lines.shift # jump table data
          end
          it { @result.should == 'end' }
          it { @jump.should match(/\Ajump/) }
          it 'each "e","n","d" include output in flash-mode' do
            @lines.all?{|l| l.match(/\Astep:/)}.should be_false
          end
        end
      end

      describe '#debug_execute_from_file' do
        context 'non params' do
          before do
            @result = @exec.debug_execute_from_file(@source_file)
            @lines = @out.string.each_line.to_a
            @jump = @lines.delete_at(0) # "jump table"
            @lines.shift # jump table data
          end
          it { @result.should == 'end' }
          it { @jump.should match(/\Ajump/) }
          it 'only debug outout in normal-mode' do
            @lines.all?{|l| l.match(/\Astep:/)}.should be_true
          end
        end

        context 'with params' do
          before do
            @result = @exec.debug_execute_from_file(@source_file, :flash => true)
            @lines = @out.string.each_line.to_a
            @jump = @lines.delete_at(0) # "jump table"
            @lines.shift # jump table data
          end
          it { @result.should == 'end' }
          it { @jump.should match(/\Ajump/) }
          it 'each "e","n","d" include output in flash-mode' do
            @lines.all?{|l| l.match(/\Astep:/)}.should be_false
          end
        end
      end

      after { $stdout = @org_out }
    end
  end

end
