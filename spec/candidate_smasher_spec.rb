require 'json'
require './lib/candidate_smasher'

RSpec.describe CandidateSmasher do
  let(:base_content) do { "@type" => CandidateSmasher::SPEK_IRI,
          CandidateSmasher::HAS_PERFORMER_IRI=> [
            {"@id" => "http://example.com/P1"},
            {"@id" => "http://example.com/P2"},
            {"@id" => "http://example.com/P3"} ],
          CandidateSmasher::USES_TEMPLATE_IRI => [
            {"@id" => "https://inferences.es/app/onto#TPLT001"},
            {"@id" => "https://inferences.es/app/onto#TPLT002"},
            {"@id" => "https://inferences.es/app/onto#TPLT003"} ],
          CandidateSmasher::USES_ISR_IRI => [] }
  end

  let(:blank_content) do { "@type" => CandidateSmasher::SPEK_IRI,
          CandidateSmasher::HAS_PERFORMER_IRI=> [],
          CandidateSmasher::USES_TEMPLATE_IRI => [],
          CandidateSmasher::USES_ISR_IRI => [] }
  end

  let(:template_content) do
    {
      "@graph":[
      {
        "@id": "https://inferences.es/app/onto#TPLT001",
        "@type": "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
        "name": "t1",
        "performer_cardinality": 2
      },
      {
        "@id": "https://inferences.es/app/onto#TPLT002",
        "@type": "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
        "name": "t2",
        "performer_cardinality": 1
      } ]
    }
  end
  
  let(:smasher_empty) { CandidateSmasher.new '{}' }

  let(:smasher_blank) do
    c = CandidateSmasher.new 
    c.spek_hsh = blank_content
    c
  end

  let(:smasher_base) do
    c = CandidateSmasher.new 
    c.spek_hsh = base_content
    c
  end

  describe "#initialize" do
    it "defaults to empty hash on bad json" do
      expect(smasher_empty.spek_hsh).to eq({})
    end

    it "defaults to empty template graph" do
      expect(smasher_empty.template_lib.empty?).to be true
    end

  end

  describe "#valid?" do
    context "with empty content" do
      it "is not valid" do
        expect(smasher_empty.valid?).to be false
      end
    end

    context "with blank content" do
      it "requires @type property" do
        smasher_blank.spek_hsh.delete("@type")
        expect(smasher_blank.valid?).to be(false)
      end

      it "requires @type property is spek" do
        smasher_blank.spek_hsh["@type"] = "http://example.com/not/a/spek"
        expect(smasher_blank.valid?).to be(false)
      end

      it "checks for required attributes" do
        smasher_blank.spek_hsh.delete(CandidateSmasher::HAS_PERFORMER_IRI)
        expect(smasher_blank.valid?).to be(false)
      end

      it "is valid when required attributes are present" do
        expect(smasher_blank.valid?).to be(true)
      end
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

  describe "#generate_candidates" do
    context "with empty content" do
      it "returns empty" do
        expect(smasher_empty.generate_candidates).to be_empty
      end
    end

    context "with multiple content" do
      it "returns (performers times templates) number of candidates " do
        expect(smasher_base.generate_candidates.length).to be(9)
      end

      it "returns candidates with unique ids" do
        cands = smasher_base.generate_candidates
        expect(cands.length).to be(cands.uniq.length)
      end
    end
  end

  describe "#smash!" do
    context "with empty content" do
      it "adds candidates to the spek" do
        smasher_empty.smash!
        expect(smasher_empty.spek_hsh.has_key?(CandidateSmasher::HAS_CANDIDATE_IRI)).to be(true)
      end

      it "returns json" do
        result = smasher_empty.smash!
        expect{
          JSON.parse(result)
        }.not_to raise_error
      end
    end

    context "with template metadata" do
    end

    context "with multiple content" do
      it "adds candidates to the spek" do
        smasher_base.smash!
        expect(smasher_base.spek_hsh.has_key?(CandidateSmasher::HAS_CANDIDATE_IRI)).to be(true)
      end

      it "is idempotent" do
        smasher_base.smash!
        h1 = smasher_base.spek_hsh.dup
        smasher_base.smash!
        expect(smasher_base.spek_hsh).to eq(h1)
      end

      it "returns json" do
        result = smasher_base.smash!
        expect{
          JSON.parse(result)
        }.not_to raise_error
      end
    end
  end
end
