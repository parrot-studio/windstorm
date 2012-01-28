# coding: utf-8
require 'spec_helper'
require 'stringio'

describe Windstorm::Machine do

  describe '#step_execute' do
    before do
      @machine = Machine.new
      @size = 10
      @machine.size = @size
    end

    describe ':pinc' do
      context 'in-range' do
        before { @machine.commands = [:pinc, :pinc, :pinc] }

        it do
          @machine.step.should == 0
          @machine.index.should == 0
          @machine.point.should == 0
          @machine.buffer.should be_empty
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          3.times do |i|
            @machine.step_execute

            @machine.step.should == i+1
            @machine.index.should == i+1
            @machine.point.should == i+1
            @machine.buffer.should be_empty
            @machine.clip_value.should == 0
            @machine.result.should be_empty
          end

          @machine.should be_finish
        end
      end

      context 'out-range' do
        before do
          @machine.commands = [:pinc] * @size
          (@size - 1).times{ @machine.step_execute }
        end

        context 'strict mode' do
          it { lambda{ @machine.step_execute }.should raise_error }
        end

        context 'loose mode' do
          before { @machine.loose = true }

          it do
            @machine.step_execute

            @machine.step.should == @size
            @machine.index.should == @size
            @machine.point.should == @size
            @machine.buffer.should be_empty
            @machine.clip_value.should == 0
            @machine.result.should be_empty

            @machine.should be_finish
          end
        end
      end
    end

    describe ':pdec' do
      context 'in-range' do
        before do
          @machine.commands = [:pinc] * 3 + [:pdec] * 3
          3.times { @machine.step_execute }
        end

        it do
          @machine.step.should == 3
          @machine.index.should == 3
          @machine.point.should == 3
          @machine.buffer.should be_empty
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          3.times do |i|
            @machine.step_execute

            @machine.step.should == i+4
            @machine.index.should == i+4
            @machine.point.should == 2-i
            @machine.buffer.should be_empty
            @machine.clip_value.should == 0
            @machine.result.should be_empty
          end

          @machine.should be_finish
        end
      end

      context 'out-range' do
        before do
          @machine.commands = [:pinc] * 2 + [:pdec] * 3
          4.times{ @machine.step_execute }
        end

        context 'strict mode' do
          it { lambda{ @machine.step_execute }.should raise_error }
        end

        context 'loose mode' do
          before { @machine.loose = true }

          it do
            @machine.step_execute

            @machine.step.should == 5
            @machine.index.should == 5
            @machine.point.should == -1
            @machine.buffer.should be_empty
            @machine.clip_value.should == 0
            @machine.result.should be_empty

            @machine.should be_finish
          end
        end
      end
    end

    describe ':inc' do
      before { @machine.commands = [:inc, :inc, :pinc, :inc, :pdec, :inc] }

      it do
        @machine.step.should == 0
        @machine.index.should == 0
        @machine.point.should == 0
        @machine.buffer.should be_empty
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        2.times do |i|
          @machine.step_execute

          @machine.step.should == i+1
          @machine.index.should == i+1
          @machine.point.should == 0
          @machine.buffer.should == [i+1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty
        end

        @machine.step_execute

        @machine.step.should == 3
        @machine.index.should == 3
        @machine.point.should == 1
        @machine.buffer.should == [2]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 4
        @machine.index.should == 4
        @machine.point.should == 1
        @machine.buffer.should == [2, 1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 5
        @machine.index.should == 5
        @machine.point.should == 0
        @machine.buffer.should == [2, 1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 6
        @machine.index.should == 6
        @machine.point.should == 0
        @machine.buffer.should == [3, 1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.should be_finish
      end
    end

    describe ':dec' do
      context 'in-range' do
        before do
          com_init = [:inc, :inc, :inc, :pinc] * 3 + [:pdec] * 3
          com = com_init + [:dec, :pinc, :dec, :dec, :pdec, :dec ]
          @init_size = com_init.size
          @machine.commands = com
          @init_size.times{ @machine.step_execute }
        end

        it do
          @machine.step.should == @init_size
          @machine.index.should == @init_size
          @machine.point.should == 0
          @machine.buffer.should == [3, 3, 3]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == @init_size + 1
          @machine.index.should == @init_size + 1
          @machine.point.should == 0
          @machine.buffer.should == [2, 3, 3]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == @init_size + 2
          @machine.index.should == @init_size + 2
          @machine.point.should == 1
          @machine.buffer.should == [2, 3, 3]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          2.times do |i|
            @machine.step_execute

            @machine.step.should == @init_size + 3 + i
            @machine.index.should == @init_size + 3 + i
            @machine.point.should == 1
            @machine.buffer.should == [2, 2 - i, 3]
            @machine.clip_value.should == 0
            @machine.result.should be_empty
          end

          @machine.step_execute

          @machine.step.should == @init_size + 5
          @machine.index.should == @init_size + 5
          @machine.point.should == 0
          @machine.buffer.should == [2, 1, 3]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == @init_size + 6
          @machine.index.should == @init_size + 6
          @machine.point.should == 0
          @machine.buffer.should == [1, 1, 3]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.should be_finish
        end
      end

      context 'out-range' do
        before do
          @machine.commands = [:inc] * 2 + [:dec] * 3
          4.times{ @machine.step_execute }
        end

        context 'strict mode' do
          it { lambda{ @machine.step_execute }.should raise_error }
        end

        context 'loose mode' do
          before { @machine.loose = true }

          it do
            @machine.step_execute

            @machine.step.should == 5
            @machine.index.should == 5
            @machine.point.should == 0
            @machine.buffer.should == [-1]
            @machine.clip_value.should == 0
            @machine.result.should be_empty

            @machine.should be_finish
          end
        end
      end
    end

    describe ':out' do
      before(:all) do
        @out = StringIO.new
        @org_out = $stdout
        $stdout = @out
      end

      before do
        @num_a = 'a'.bytes.first
        com_init = [:inc] * @num_a
        com = com_init + [:out, :inc, :out, :dec, :out]
        @machine.commands = com
        @num_a.times{ @machine.step_execute }
      end

      context 'normal mode' do
        it do
          @machine.step.should == @num_a
          @machine.index.should == @num_a
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should be_empty
          @out.string.should be_empty

          @machine.step_execute

          @machine.step.should == @num_a + 1
          @machine.index.should == @num_a + 1
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should == 'a'
          @out.string.should be_empty

          @machine.step_execute

          @machine.step.should == @num_a + 2
          @machine.index.should == @num_a + 2
          @machine.point.should == 0
          @machine.buffer.should == [@num_a+1]
          @machine.clip_value.should == 0
          @machine.result.should == 'a'
          @out.string.should be_empty

          @machine.step_execute

          @machine.step.should == @num_a + 3
          @machine.index.should == @num_a + 3
          @machine.point.should == 0
          @machine.buffer.should == [@num_a+1]
          @machine.clip_value.should == 0
          @machine.result.should == 'ab'
          @out.string.should be_empty

          @machine.step_execute

          @machine.step.should == @num_a + 4
          @machine.index.should == @num_a + 4
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should == 'ab'
          @out.string.should be_empty

          @machine.step_execute

          @machine.step.should == @num_a + 5
          @machine.index.should == @num_a + 5
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should == 'aba'
          @out.string.should be_empty

          @machine.should be_finish
        end
      end

      context 'flash mode' do
        before{ @machine.flash = true }

        it do
          @machine.step.should == @num_a
          @machine.index.should == @num_a
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should be_empty
          @out.string.should be_empty

          @machine.step_execute

          @machine.step.should == @num_a + 1
          @machine.index.should == @num_a + 1
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should == 'a'
          @out.string.should == 'a'

          @machine.step_execute

          @machine.step.should == @num_a + 2
          @machine.index.should == @num_a + 2
          @machine.point.should == 0
          @machine.buffer.should == [@num_a+1]
          @machine.clip_value.should == 0
          @machine.result.should == 'a'
          @out.string.should == 'a'

          @machine.step_execute

          @machine.step.should == @num_a + 3
          @machine.index.should == @num_a + 3
          @machine.point.should == 0
          @machine.buffer.should == [@num_a+1]
          @machine.clip_value.should == 0
          @machine.result.should == 'ab'
          @out.string.should == 'ab'

          @machine.step_execute

          @machine.step.should == @num_a + 4
          @machine.index.should == @num_a + 4
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should == 'ab'
          @out.string.should == 'ab'

          @machine.step_execute

          @machine.step.should == @num_a + 5
          @machine.index.should == @num_a + 5
          @machine.point.should == 0
          @machine.buffer.should == [@num_a]
          @machine.clip_value.should == 0
          @machine.result.should == 'aba'
          @out.string.should == 'aba'

          @machine.should be_finish
        end
      end

      after(:all) { $stdout = @org_out }
    end

    describe ':inp' do
      before(:all) do
        @in = StringIO.new('orz')
        @org_in = $stdin
        $stdin = @in
      end

      before do
        @ins = 'orz'.bytes.to_a
        @machine.commands = [:inp, :pinc, :inp, :pinc, :inp, :dec]
      end

      it do
        @machine.step.should == 0
        @machine.index.should == 0
        @machine.point.should == 0
        @machine.buffer.should be_empty
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 1
        @machine.index.should == 1
        @machine.point.should == 0
        @machine.buffer.should == [@ins[0]]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 2
        @machine.index.should == 2
        @machine.point.should == 1
        @machine.buffer.should == [@ins[0]]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 3
        @machine.index.should == 3
        @machine.point.should == 1
        @machine.buffer.should == [@ins[0], @ins[1]]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 4
        @machine.index.should == 4
        @machine.point.should == 2
        @machine.buffer.should == [@ins[0], @ins[1]]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 5
        @machine.index.should == 5
        @machine.point.should == 2
        @machine.buffer.should == [@ins[0], @ins[1], @ins[2]]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 6
        @machine.index.should == 6
        @machine.point.should == 2
        @machine.buffer.should == [@ins[0], @ins[1], @ins[2]-1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.should be_finish
      end

      after(:all) { $stdin = @org_in }
    end

    describe ':jmp/:ret' do
      context 'jump commands' do
        before do
          @machine.commands = [:inc, :dec, :jmp, :inc, :inc, :ret, :inc]
          @machine.parse_jump
        end

        it do
          @machine.jump_table.should == {2 => 5, 5 => 2}

          2.times{ @machine.step_execute }

          @machine.step.should == 2
          @machine.index.should == 2
          @machine.point.should == 0
          @machine.buffer.should == [0]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 3
          @machine.index.should == 6
          @machine.point.should == 0
          @machine.buffer.should == [0]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 4
          @machine.index.should == 7
          @machine.point.should == 0
          @machine.buffer.should == [1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.should be_finish
        end
      end

      context 'loop' do
        before do
          @machine.commands = [:inc, :inc, :jmp, :dec, :ret, :inc]
          @machine.parse_jump
        end

        it do
          @machine.jump_table.should == {2 => 4, 4 => 2}

          2.times{ @machine.step_execute }

          @machine.step.should == 2
          @machine.index.should == 2
          @machine.point.should == 0
          @machine.buffer.should == [2]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 3
          @machine.index.should == 3
          @machine.point.should == 0
          @machine.buffer.should == [2]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 4
          @machine.index.should == 4
          @machine.point.should == 0
          @machine.buffer.should == [1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 5
          @machine.index.should == 3
          @machine.point.should == 0
          @machine.buffer.should == [1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 6
          @machine.index.should == 4
          @machine.point.should == 0
          @machine.buffer.should == [0]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 7
          @machine.index.should == 5
          @machine.point.should == 0
          @machine.buffer.should == [0]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 8
          @machine.index.should == 6
          @machine.point.should == 0
          @machine.buffer.should == [1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.should be_finish
        end
      end

      context 'nested' do
        before do
          @machine.commands = [:inc, :jmp, :dec, :jmp, :pinc, :inc, :ret, :ret, :inc]
          @machine.parse_jump
        end

        it do
          @machine.jump_table.should == {1 => 7, 7 => 1, 3 => 6, 6 => 3}

          @machine.step_execute

          @machine.step.should == 1
          @machine.index.should == 1
          @machine.point.should == 0
          @machine.buffer.should == [1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 2
          @machine.index.should == 2
          @machine.point.should == 0
          @machine.buffer.should == [1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 3
          @machine.index.should == 3
          @machine.point.should == 0
          @machine.buffer.should == [0]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 4
          @machine.index.should == 7
          @machine.point.should == 0
          @machine.buffer.should == [0]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 5
          @machine.index.should == 8
          @machine.point.should == 0
          @machine.buffer.should == [0]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.step_execute

          @machine.step.should == 6
          @machine.index.should == 9
          @machine.point.should == 0
          @machine.buffer.should == [1]
          @machine.clip_value.should == 0
          @machine.result.should be_empty

          @machine.should be_finish
        end
      end
    end

    describe ':clip' do
      before { @machine.commands = [:inc, :clip, :pinc, :clip] }

      it do
        @machine.step_execute

        @machine.step.should == 1
        @machine.index.should == 1
        @machine.point.should == 0
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 2
        @machine.index.should == 2
        @machine.point.should == 0
        @machine.buffer.should == [1]
        @machine.clip_value.should == 1
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 3
        @machine.index.should == 3
        @machine.point.should == 1
        @machine.buffer.should == [1]
        @machine.clip_value.should == 1
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 4
        @machine.index.should == 4
        @machine.point.should == 1
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.should be_finish
      end
    end

    describe ':paste' do
      before { @machine.commands = [:paste, :inc, :clip, :pinc, :paste] }

      it do
        @machine.step_execute

        @machine.step.should == 1
        @machine.index.should == 1
        @machine.point.should == 0
        @machine.buffer.should == [0]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 2
        @machine.index.should == 2
        @machine.point.should == 0
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 3
        @machine.index.should == 3
        @machine.point.should == 0
        @machine.buffer.should == [1]
        @machine.clip_value.should == 1
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 4
        @machine.index.should == 4
        @machine.point.should == 1
        @machine.buffer.should == [1]
        @machine.clip_value.should == 1
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 5
        @machine.index.should == 5
        @machine.point.should == 1
        @machine.buffer.should == [1, 1]
        @machine.clip_value.should == 1
        @machine.result.should be_empty

        @machine.should be_finish
      end
    end

    context 'unknown command' do
      before { @machine.commands = [:inc, :hoge, :pinc, :piyo, :pdec] }

      it do
        @machine.step_execute

        @machine.step.should == 1
        @machine.index.should == 1
        @machine.point.should == 0
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 2
        @machine.index.should == 2
        @machine.point.should == 0
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 3
        @machine.index.should == 3
        @machine.point.should == 1
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 4
        @machine.index.should == 4
        @machine.point.should == 1
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.step_execute

        @machine.step.should == 5
        @machine.index.should == 5
        @machine.point.should == 0
        @machine.buffer.should == [1]
        @machine.clip_value.should == 0
        @machine.result.should be_empty

        @machine.should be_finish
      end
    end
  end

  describe '#execute' do
    before do
      coms = [
        :pinc, [:inc] * 10,
        :jmp, :pdec,
        [:inc] * 10,
        :pinc, :dec, :ret,
        :pdec, :clip,
        :inc, :out,
        :pinc, [:inc] * 3,
        :jmp, :pdec,
        [:inc] * 3,
        :pinc, :dec, :ret,
        :pdec, :out,
        :paste, :out
      ].flatten
      @machine = Machine.create(coms)
    end

    context 'normal mode' do
      it do
        @machine.execute.should == 'end'
        @machine.result.should == 'end'
      end
    end

    context 'flash mode' do
      before do
        @out = StringIO.new
        @org_out = $stdout
        $stdout = @out
        @machine.flash = true
      end

      it do
        @machine.execute.should == 'end'
        @machine.result.should == 'end'
        @out.string.should == 'end'
      end

      after { $stdout = @org_out }
    end

    context 'not execute if machine has result already' do
      before do
        @result = @machine.execute
        @index = @machine.index
        @step = @machine.step
      end

      it do
        @machine.execute.should == @result
        @machine.index.should == @index
        @machine.step.should == @step
      end
    end
  end

end
