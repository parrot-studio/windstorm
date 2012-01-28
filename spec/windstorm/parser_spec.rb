# coding: utf-8
require 'spec_helper'

describe Windstorm::Parser do

  describe '#table/#table=' do
    context 'raise error if not table seted or empty' do
      it { lambda{ Parser.new.table}.should raise_error }
      it { lambda{ Parser.create({}) }.should raise_error }
    end

    context 'set commands table' do
      before do
        @table = {:pinc => ['hoge', 'piyo'], :inc => 'aborn'}
        @expect = {:pinc => ['hoge', 'piyo'], :inc => ['aborn']}
      end
      subject { Parser.create(@table) }
      its(:table) { should == @expect }
    end

    context 'not commands table, raise error' do
      before do
        @table = {:a => 'hoge', :b => 'piyo'}
        @ps = Parser.new
      end
      it { lambda{ @ps.table = @table }.should raise_error }
    end
  end

  describe '#dict' do
    context 'raise error if not table seted' do
      it { lambda{ Parser.new.dict }.should raise_error }
    end

    context 'get reverse table' do
      before do
        @table = {:pinc => ['hoge', 'piyo'], :inc => 'aborn'}
        @expect = {'hoge' => :pinc, 'piyo' => :pinc, 'aborn' => :inc}
      end
      subject{ Parser.create(@table) }
      its(:dict) { should == @expect }
    end
  end

  describe '#filter' do
    context 'source filter with dict' do
      before do
        @table = {:pinc => ['+', '/'], :inc => '(´･ω･`)'}
        @source = '+dsa+(´･ω･`)-rqwyuiyiu-(`･ω･´)*;;;:::das( ´･ω･` )kl;das*(´-ω-)/>>>../'
        @expect = ['+', '+', '(´･ω･`)', '/', '/']
        @parser = Parser.create(@table)
      end
      it { @parser.filter(@source).should == @expect }
    end

    context 'reject comment lines' do
      before do
        @table = {:inc => ['b', 'c']}
        @source = <<-EOS
abc
# cba # comment
// cba // comment
 # cba # spece head
 // cba // spece head
        EOS
        @expect = ['b', 'c', 'c', 'b', 'c', 'c', 'b', 'c']
        @parser = Parser.create(@table)
      end
      it { @parser.filter(@source).should == @expect }
    end

    context 'empty array for no hit' do
      before do
        @table = {:inc => ['b', 'c']}
        @source = '(´･ω･`)'
        @parser = Parser.create(@table)
      end
      it { @parser.filter(@source).should be_empty }
    end

    context 'given nil' do
      before do
        @table = {:inc => ['b', 'c']}
        @parser = Parser.create(@table)
      end
      it { @parser.filter(nil).should be_empty }
    end
  end

  describe '#convert' do
    context 'convert word to command' do
      before do
        @table = {:pinc => '12', :pdec => '3', :inc => '5'}
        @filtered = ['3', '12', '21', '5']
        @expect = [:pdec, :pinc, :inc]
        @parser = Parser.create(@table)
      end
      it { @parser.convert(@filtered).should == @expect }
    end

    context 'empty list or nil' do
      before do
        @table = {:pinc => '12', :pdec => '3', :inc => '5'}
        @parser = Parser.create(@table)
      end
      it { @parser.convert(nil).should be_empty }
      it { @parser.convert([]).should be_empty }
    end
  end

  describe '#build' do
    context 'build commands from source' do
      before do
        @table = {:pinc => ['+', '/'], :inc => '(´･ω･`)'}
        @source = '+dsa+(´･ω･`)-rqwyuiyiu-(`･ω･´)*;;;:::das( ´･ω･` )kl;das*(´-ω-)/>>>../'
        @expect = [:pinc, :pinc, :inc, :pinc, :pinc]
        @parser = Parser.create(@table)
      end
      it { @parser.build(@source).should == @expect }
    end

    context 'no commands included' do
      before do
        @table = {:pinc => '12', :pdec => '3', :inc => '5'}
        @source = 'ta-noshi-na-kama-ga-'
        @parser = Parser.create(@table)
      end
      it { @parser.build(@source).should be_empty }
      it { @parser.build(nil).should be_empty }
    end
  end

end
