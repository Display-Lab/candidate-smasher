require './lib/can_smash_cli'

RSpec.describe CanSmashCLI do
  context "Without options" do
    let(:options) {Hash.new} 
      it "reads from stdin" do
      end
  end

  context "With path global option" do
    it "reads from a file" do
    end
  end

  context "With path option" do
    it "reads from file" do
    end

    it "overrides global option" do
    end
  end
end
