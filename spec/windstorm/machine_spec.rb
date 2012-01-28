# coding: utf-8
require 'spec_helper'
require "stringio"

describe Windstorm::Machine do

  describe '#finish?' do
    before { @machine = Machine.create([:inc, :inc, :inc]) }
    it { @machine.finish?.should be_false }
    it { 2.times{ @machine.add_index }; @machine.finish?.should be_false }
    it { 3.times{ @machine.add_index }; @machine.finish?.should be_true }
  end

  describe '#parse_jump' do
    context 'normal :jmp and :ret' do
      before do
        @coms = [:inc, :jmp, :inc, :ret, :jmp, :dec, :dec, :ret, :pinc]
        @expect = {1 => 3, 3 => 1, 4 => 7, 7 => 4}
        @machine = Machine.create(@coms)
        @machine.parse_jump
      end
      it { @machine.jump_table.should == @expect }
    end

    context 'nested :jmp' do
      before do
        @coms = [:inc, :jmp, :inc, :jmp, :dec, :dec, :ret, :pinc, :ret]
        @expect = {3 => 6, 6 => 3, 1 => 8, 8 => 1}
        @machine = Machine.create(@coms)
        @machine.parse_jump
      end
      it { @machine.jump_table.should == @expect }
    end

    context 'no :jmp or :ret' do
      before do
        @coms = [:inc, :inc, :dec, :dec, :pinc, :pdec]
        @machine = Machine.create(@coms)
        @machine.parse_jump
      end
      it { @machine.jump_table.should be_empty }
    end

    context 'lack　:jmp' do
      before do
        @coms = [:inc, :jmp, :inc, :dec, :dec, :ret, :pinc, :ret]
        @machine = Machine.create(@coms)
      end
      it { lambda{ @machine.parse_jump }.should raise_error }
    end

    context 'lack　:ret' do
      before do
        @coms = [:inc, :jmp, :inc, :jmp, :dec, :dec, :pinc, :ret]
        @machine = Machine.create(@coms)
      end
      it { lambda{ @machine.parse_jump }.should raise_error }
    end
  end

  describe '#jump_index' do
    before do
      @machine = Machine.create([:inc,:inc,:inc,:inc,:inc])
      @machine.add_index
    end

    context 'strict mode' do
      context 'in-range' do
        it { @machine.jump_index(0); @machine.index.should == 0 }
        it { @machine.jump_index(4); @machine.index.should == 4 }
      end

      context 'out-range' do
        it { lambda{ @machine.jump_index(-1) }.should raise_error }
        it { lambda{ @machine.jump_index(5) }.should raise_error }
      end
    end

    context 'loose mode' do
      before { @machine.loose = true }

      context 'in-range' do
        it { @machine.jump_index(0); @machine.index.should == 0 }
        it { @machine.jump_index(4); @machine.index.should == 4 }
      end

      context 'out-range' do
        it { @machine.jump_index(-1); @machine.index.should == -1 }
        it { @machine.jump_index(5); @machine.index.should == 5 }
      end
    end

    context 'invalid index' do
      it { lambda{ @machine.jump_index(nil) }.should raise_error }
    end
  end

  describe '#jump' do
    def jump_check(ind, rsl)
      ind.times{ @machine.add_index }

      case rsl
      when :err
        lambda{ @machine.jump }.should raise_error
      else
        @machine.jump
        @machine.index.should == rsl
      end
    end

    before do
      @coms = [:inc, :jmp, :inc, :jmp, :dec, :dec, :ret, :pinc, :ret]
      @machine = Machine.create(@coms)
      @machine.parse_jump
    end

    context 'exist index in table' do
      it { jump_check(1, 8) }
      it { jump_check(3, 6) }
      it { jump_check(6, 3) }
      it { jump_check(8, 1) }
    end

    context 'non exist index in table' do
      it { jump_check(0, :err) }
      it { jump_check(4, :err) }
      it { jump_check(9, :err) }
    end
  end

  describe '#size' do
    before do
      @machine = Machine.new
      @default = BUFFER_DEFAULT_SIZE
    end

    context 'set size' do
      it { @machine.size = 200; @machine.size.should == 200 }
    end

    context 'default size if not seted' do
      it { @machine.size.should == @default }
    end

    context 'default size if invalid size set' do
      it { @machine.size = -1; @machine.size.should == @default }
    end
  end

  describe '#move_point_inc' do
    before do
      @machine = Machine.new
      @size = 10
      @machine.size = @size
    end

    context 'strict mode' do
      it 'in-range' do
        (0...(@size-1)).each do |i|
          @machine.move_point_inc
          @machine.point.should == i+1
        end
      end

      context 'out-range' do
        before do
          (@size-1).times { @machine.move_point_inc }
        end
        it { lambda { @machine.move_point_inc }.should raise_error }
      end
    end

    context 'loose mode' do
      before { @machine.loose = true }

      it 'in-range' do
        (0...(@size-1)).each do |i|
          @machine.move_point_inc
          @machine.point.should == i+1
        end
      end

      context 'out-range' do
        before do
          (@size-1).times { @machine.move_point_inc }
        end
        it { @machine.move_point_inc; @machine.point.should == @size }
      end
    end
  end

  describe '#move_point_dec' do
    before do
      @machine = Machine.new
      @size = 10
      @machine.size = @size
      (@size-1).times { @machine.move_point_inc }
    end

    context 'strict mode' do
      it 'in-range' do
        (0...(@size-1)).each do |i|
          @machine.move_point_dec
          @machine.point.should == @size - 2 - i
        end
      end

      context 'out-range' do
        before { (@size-1).times { @machine.move_point_dec } }
        it { lambda { @machine.move_point_dec }.should raise_error }
      end
    end

    context 'loose mode' do
      before { @machine.loose = true }

      it 'in-range' do
        (0...(@size-1)).each do |i|
          @machine.move_point_dec
          @machine.point.should == @size - 2 - i
        end
      end

      context 'out-range' do
        before do
          (@size-1).times { @machine.move_point_dec }
        end
        it { @machine.move_point_dec; @machine.point.should == -1 }
      end
    end
  end

  describe '#value' do
    before do
      @machine = Machine.new
      @size = 10
      @machine.size = @size
    end

    context 'strict mode' do
      context 'default value is 0' do
        it do
          (@size-1).times do
            @machine.value.should == 0
            @machine.move_point_inc
          end
        end

        it do
          (@size-1).times do |i|
            @machine.value(i).should == 0
          end
        end
      end

      context 'over point' do
        it { lambda{ @machine.value(-1) }.should raise_error }
        it { lambda{ @machine.value(@size) }.should raise_error }
      end
    end

    context 'loose mode' do
      before { @machine.loose = true }

      context 'default value is 0' do
        it do
          (@size-1).times do
            @machine.value.should == 0
            @machine.move_point_inc
          end
        end

        it do
          (@size-1).times do |i|
            @machine.value(i).should == 0
          end
        end
      end

      context 'over point' do
        it { lambda{ @machine.value(-1) }.should_not raise_error }
        it { lambda{ @machine.value(@size) }.should_not raise_error }
      end
    end
  end

  describe '#replace_value' do
    before do
      @machine = Machine.new
      @size = 10
      @machine.size = @size
    end

    context 'strict mode' do
      context 'in-range' do
        it do
          (@size-1).times do |i|
            @machine.replace_value(i+1).should == i+1
            @machine.value.should == i+1
            @machine.move_point_inc
          end
        end

        it do
          (@size-1).times do |i|
            @machine.replace_value(i+1, i).should == i+1
            @machine.value(i).should == i+1
          end
        end
      end

      context 'out-range' do
        it { lambda{ @machine.replace_value(1, -1)}.should raise_error }
        it { lambda{ @machine.replace_value(1, @size)}.should raise_error }
      end

      context 'value under 0' do
        it { lambda{ @machine.replace_value(-1)}.should raise_error }
        it { lambda{ @machine.replace_value(-1, 1)}.should raise_error }
      end
    end

    context 'loose mode' do
      before { @machine.loose = true }

      context 'in-range' do
        it do
          (@size-1).times do |i|
            @machine.replace_value(i+1).should == i+1
            @machine.value.should == i+1
            @machine.move_point_inc
          end
        end

        it do
          (@size-1).times do |i|
            @machine.replace_value(i+1, i).should == i+1
            @machine.value(i).should == i+1
          end
        end
      end

      context 'out-range' do
        it { lambda{ @machine.replace_value(1, -1)}.should raise_error(IndexError) }
        it { lambda{ @machine.replace_value(1, @size)}.should_not raise_error }
      end

      context 'value under 0' do
        it { lambda{ @machine.replace_value(-1)}.should_not raise_error }
        it { lambda{ @machine.replace_value(-1, 1)}.should_not raise_error }
      end
    end
  end

  describe '#increment' do
    before { @machine = Machine.new }

    it 'increment value' do
      10.times do |i|
        @machine.increment
        @machine.value.should == i+1
      end
    end

    context 'another point' do
      before do
        2.times { @machine.increment }
        @machine.move_point_inc
        4.times { @machine.increment }
      end
      it { @machine.value(0).should == 2 }
      it { @machine.value(1).should == 4 }
      it { @machine.value(2).should == 0 }
    end
  end

  describe '#decrement' do
    before do
      @machine = Machine.new
      5.times{ @machine.increment }
      @machine.move_point_inc
      5.times{ @machine.increment }
      @machine.move_point_dec
    end

    it 'decrement value' do
      5.times do |i|
        @machine.decrement
        @machine.value.should == 4 - i
      end
    end

    context 'another point' do
      before do
        2.times { @machine.decrement }
        @machine.move_point_inc
        4.times { @machine.decrement }
      end
      it { @machine.value(0).should == 3 }
      it { @machine.value(1).should == 1 }
      it { @machine.value(2).should == 0 }
    end

    context 'value under 0' do
      before do
        5.times { @machine.decrement }
      end

      context 'strict mode' do
        it { lambda { @machine.decrement }.should raise_error }
      end

      context 'loose mode' do
        before { @machine.loose = true }
        it { @machine.decrement; @machine.value.should == -1 }
      end
    end
  end

  describe '#output' do
    before do
      @out = StringIO.new
      @org_out = $stdout
      $stdout = @out
      @machine = Machine.new
    end

    context 'normal mode' do
      it do
        'a'.bytes.first.times{ @machine.increment }
        @machine.output
        @machine.cache.should == 'a'
        @machine.result.should == 'a'
        @out.string.should be_empty

        @machine.increment
        @machine.output
        @machine.cache.should == 'ab'
        @machine.result.should == 'ab'
        @out.string.should be_empty

        @machine.decrement
        @machine.output
        @machine.cache.should == 'aba'
        @machine.result.should == 'aba'
        @out.string.should be_empty
      end
    end

    context 'flash mode' do
      before { @machine.flash = true }

      it do
        'a'.bytes.first.times{ @machine.increment }
        @machine.output
        @machine.cache.should == 'a'
        @machine.result.should == 'a'
        @out.string.should == 'a'

        @machine.increment
        @machine.output
        @machine.cache.should == 'ab'
        @machine.result.should == 'ab'
        @out.string.should == 'ab'

        @machine.decrement
        @machine.output
        @machine.cache.should == 'aba'
        @machine.result.should == 'aba'
        @out.string.should == 'aba'
      end
    end

    after { $stdout = @org_out }
  end

  describe '#input' do
    before do
      @in = StringIO.new('aba')
      @org_in = $stdin
      $stdin = @in
      @machine = Machine.new
    end

    it do
      @machine.input
      @machine.value.should == 'a'.bytes.first
      @machine.value(0).should == 'a'.bytes.first

      @machine.input
      @machine.value.should == 'b'.bytes.first
      @machine.value(0).should == 'b'.bytes.first

      @machine.move_point_inc
      @machine.input
      @machine.value.should == 'a'.bytes.first
      @machine.value(0).should == 'b'.bytes.first
      @machine.value(1).should == 'a'.bytes.first
    end

    after { $stdin = @org_in }
  end

  describe '#clip_value/#replace_clip_value' do
    before { @machine = Machine.new }

    context 'strict mode' do
      context 'return 0 if not cliped' do
        it { @machine.clip_value.should == 0 }
      end

      context 'clip and get' do
        context 'valid value' do
          it do
            @machine.replace_clip_value(10).should == 10
            @machine.clip_value.should == 10
            @machine.clip_value.should == 10
          end
        end

        context 'value under 0' do
          it { lambda{ @machine.replace_clip_value(-1) }.should raise_error }
        end
      end

      context 'overwrite value' do
        it do
          @machine.replace_clip_value(10).should == 10
          @machine.clip_value.should == 10
          @machine.replace_clip_value(20).should == 20
          @machine.clip_value.should == 20
        end
      end
    end

    context 'loose mode' do
      before { @machine.loose = true }

      context 'return 0 if not cliped' do
        it { @machine.clip_value.should == 0 }
      end

      context 'clip and get' do
        context 'valid value' do
          it do
            @machine.replace_clip_value(10).should == 10
            @machine.clip_value.should == 10
            @machine.clip_value.should == 10
          end
        end

        context 'value under 0' do
          it do
            @machine.replace_clip_value(-1).should == -1
            @machine.clip_value.should == -1
          end
        end
      end

      context 'overwrite value' do
        it do
          @machine.replace_clip_value(10).should == 10
          @machine.clip_value.should == 10
          @machine.replace_clip_value(20).should == 20
          @machine.clip_value.should == 20
        end
      end
    end
  end

end
