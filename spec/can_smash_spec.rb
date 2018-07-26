require './lib/can_smash_cli'
require './spec/io_spec_helper'
require 'json'

RSpec.configure do |c|
  c.include IoSpecHelper
end

RSpec.describe CanSmashCLI do
  BLANK_CONTENT = { "@type" => CandidateSmasher::SPEK_IRI,
                    CandidateSmasher::HAS_PERFORMER_IRI=> [],
                    CandidateSmasher::USES_TEMPLATE_IRI => [],
                    CandidateSmasher::USES_ISR_IRI => [] 
                  }
  BLANK_JSON = BLANK_CONTENT.to_json

  TEMPLATE_MD = { 
    "@graph" => [
      { "@id"   => "https://inferences.es/app/onto#TPLT001",
        "@type" => "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
        "name"  => "t1",
        "performer_cardinality" => 2
      }] 
    }

  subject { CanSmashCLI.new }

  context "using defaults" do
    it "reads from stdin" do
      simulate_stdin(BLANK_JSON) do 
        expect {subject.generate}.to output.to_stdout
      end
    end
  end

  context "given invalid spec" do
    it "emits an error on stderr" do
      simulate_stdin('Im a invalid!') do 
        expect {subject.generate}
          .to raise_error(SystemExit)
          .and output("Invalid input spec\n").to_stderr
      end
    end
  end

  context "Spec path parameter and option:" do

    before(:all) do
      opt_content = BLANK_CONTENT.dup
      opt_content["@id"] = "option_id"

      param_content = BLANK_CONTENT.dup
      param_content["@id"] = "param_id"

      @opt_json = opt_content.to_json
      @param_json = param_content.to_json
      
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
        expect {subject.generate}.to output(/option_id/).to_stdout
      end
    end

    context "With path parameter" do

      it "reads from file in parameter" do
        @param_file.rewind
        expect {subject.generate(path=@param_file.path)}.to output(/param_id/).to_stdout
      end
    end

    context "With both parameter and option" do
      it "reads from file in paramter" do
        @param_file.rewind
        @opt_file.rewind
        subject.options = {path: @opt_file.path}

        expect {subject.generate(path=@param_file.path)}.to output(/param_id/).to_stdout
      end
    end

  end
end
