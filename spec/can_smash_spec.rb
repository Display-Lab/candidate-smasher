require './lib/can_smash_cli'
require './spec/io_spec_helper'

RSpec.configure do |c|
  c.include IoSpecHelper
end

RSpec.describe CanSmashCLI do
  subject { CanSmashCLI.new }

  context "using defaults" do
    let(:empty_json) {'{}'}

    it "reads from stdin" do
      expect(CandidateSmasher).to receive(:new).with(empty_json)
      simulate_stdin(empty_json) { subject.generate }
    end
  end

  context "Path parameters and options" do

    before(:all) do
      @opt_json = "{'foo': 'opt'}"
      @param_json = "{'bar': 'param'}"
      
      @opt_file  = Tempfile.new('opt')
      @opt_file.write(@opt_json)
      @param_file = Tempfile.new('param')
      @param_file.write(@param_json)
    end

    after(:all) do
      @opt_file.close
      @param_file.close
      @opt_file.unlink
      @param_file.unlink
    end

    context "With path option" do

      it "reads from file specified in path option" do
        @opt_file.rewind
        subject.options = {path: @opt_file.path}

        expect(CandidateSmasher).to receive(:new).with(@opt_json)
        subject.generate
      end
    end

    context "With path parameter" do

      it "reads from file in parameter" do
        @param_file.rewind
        expect(CandidateSmasher).to receive(:new).with(@param_json)
        subject.generate(path=@param_file.path)
      end
    end

    context "With both parameter and option" do
      it "reads from file in paramter" do
        @param_file.rewind
        @opt_file.rewind
        subject.options = {path: @opt_file.path}

        expect(CandidateSmasher).to receive(:new).with(@param_json)
        subject.generate(path=@param_file.path)
      end
    end

  end
end
