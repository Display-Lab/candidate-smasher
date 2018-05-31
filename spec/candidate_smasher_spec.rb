require 'json'
require './lib/candidate_smasher'

RSpec.describe CandidateSmasher do

  describe "#initialize" do
    it "defaults to empty hash on bad json" do
      cs = CandidateSmasher.new("{}}")
      expect(cs.spek_hsh).to eq({})
    end

  end

  describe "#valid?" do
    let(:content) do { "@type" => CandidateSmasher::SPEK_IRI,
            CandidateSmasher::HAS_PERFORMER_IRI=> [],
            CandidateSmasher::USES_TEMPLATE_IRI => [],
            CandidateSmasher::USES_ISR_IRI => [] }
    end

    subject do 
      c = CandidateSmasher.new 
      c.spek_hsh = content
      c
    end

    it "requires @type property" do
      subject.spek_hsh.delete("@type")
      expect(subject.valid?).to be(false)
    end

    it "requires @type property is spek" do
      subject.spek_hsh["@type"] = "http://example.com/not/a/spek"
      expect(subject.valid?).to be(false)
    end

    it "checks for required attributes" do
      subject.spek_hsh.delete(CandidateSmasher::HAS_PERFORMER_IRI)
      expect(subject.valid?).to be(false)
    end

    it "is valid when required attributes are present" do
      expect(subject.valid?).to be(true)
    end

  end

  describe "make_candidate" do
    let(:performer) { {"@id" => "http://example.com/P1",
                       "name" => "foo" } }
    let(:template) { {"@id" => "http://example.com/T1",
                       "colors" => "4" } }

    it "assigns a random id" do
      c = CandidateSmasher.make_candidate( template, performer )
      expect(c["@id"]).to match(/^candidate.internal\/[a-f0-9]{32}$/)
    end
    
    it "assigns the candidate type" do
      c = CandidateSmasher.make_candidate( template, performer )
      expect(c["@type"]).to eq(CandidateSmasher::CANDIDATE_IRI)
    end

    it "retains ancestor ids" do
      c = CandidateSmasher.make_candidate( template, performer )
      expect(c[CandidateSmasher::ANCESTOR_PERFORMER_IRI]).to eq(performer["@id"])
      expect(c[CandidateSmasher::ANCESTOR_TEMPLATE_IRI]).to eq(template["@id"])
    end

  end

  context "Aggregating Candidates" do
    let(:content) do { "@type" => CandidateSmasher::SPEK_IRI,
            CandidateSmasher::HAS_PERFORMER_IRI=> [
              {"@id" => "http://example.com/P1"},
              {"@id" => "http://example.com/P2"},
              {"@id" => "http://example.com/P3"} ],
            CandidateSmasher::USES_TEMPLATE_IRI => [
              {"@id" => "http://example.com/T1"},
              {"@id" => "http://example.com/T2"},
              {"@id" => "http://example.com/T3"} ],
            CandidateSmasher::USES_ISR_IRI => [] }
    end

    subject do 
      c = CandidateSmasher.new 
      c.spek_hsh = content
      c
    end

    describe "#generate_all" do
      it "returns (performers times templates) number of candidates " do
        expect(subject.generate_candidates.length).to be(9)
      end

      it "returns candidates with unique ids" do
        cands = subject.generate_candidates
        expect(cands.length).to be(cands.uniq.length)
      end
    end

    describe "#smash!" do
      it "adds candidates to the spek" do
        subject.smash!
        expect(subject.spek_hsh.has_key?(CandidateSmasher::HAS_CANDIDATE_IRI)).to be(true)
      end

      it "is idempotent" do
        subject.smash!
        h1 = subject.spek_hsh.dup
        subject.smash!
        expect(subject.spek_hsh).to eq(h1)
      end

      it "returns a string" do
        expect(subject.smash!.class).to be(String)
      end

      it "returns json" do
        result = subject.smash!
        expect{
          JSON.parse(result)
        }.not_to raise_error
      end
    end
  end
end
