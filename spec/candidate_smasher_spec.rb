require 'json'
require './lib/candidate_smasher'


HAS_DISPOSITION_IRI = "http://purl.obolibrary.org/obo/RO_0000091"
P_CARDINALITY_IRI = "http://example.com/ns#performer_cardinality"

def json_to_graph(json_string)
  reader = JSON::LD::Reader.new(input=json_string)
  graph = RDF::Graph.new
  graph.insert_statements reader
  return graph
end

RSpec.describe CandidateSmasher do
  let(:base_content) do
    { "@type" => CandidateSmasher::SPEK_IRI,
      CandidateSmasher::HAS_PERFORMER_IRI=> [
        {"@id" => "http://example.com/P1",
         HAS_DISPOSITION_IRI => "promotion_focus"},
        {"@id" => "http://example.com/P2",
         HAS_DISPOSITION_IRI => "prevention_focus"},
        {"@id" => "http://example.com/P3",
         HAS_DISPOSITION_IRI => "dancing"} ],
      CandidateSmasher::ABOUT_TEMPLATE_IRI => [
        {"@id" => "https://inferences.es/app/onto#TPLT001"},
        {"@id" => "https://inferences.es/app/onto#TPLT002"},
        {"@id" => "https://inferences.es/app/onto#TPLT003"} ],
      CandidateSmasher::USES_ISR_IRI => [] 
    }
  end

  let(:blank_content) do { "@type" => CandidateSmasher::SPEK_IRI,
          CandidateSmasher::HAS_PERFORMER_IRI=> [],
          CandidateSmasher::ABOUT_TEMPLATE_IRI => [],
          CandidateSmasher::USES_ISR_IRI => [] }
  end

  let(:ext_template_content) do
    {
      "@graph" => [
      {
        "@id"   => "https://inferences.es/app/onto#TPLT001",
        "@type" => "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
        "name"  => "t1",
        "performer_cardinality" => 2
      },
      {
        "@id" => "https://inferences.es/app/onto#TPLT002",
        "@type" => "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
        "name" => "t2",
        "performer_cardinality" => 1
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

  let(:smasher_ext_tmpl) do
    c = CandidateSmasher.new 
    c.spek_hsh = base_content
    c.template_lib = json_to_graph(ext_template_content.to_json)
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

  describe "#load_ext_templates" do
    context"with no external template metadata" do
      it "returns empty graph" do
        result = smasher_blank.load_ext_templates(nil)
        expect(result).to be_instance_of(RDF::Graph).and be_empty
      end
    end

    context"using external template metadata" do
      it "returns loads the graph" do
        fixture_file = 'spec/fixtures/templates-metadata.json'
        result = smasher_blank.load_ext_templates(fixture_file)

        expect(result).to be_instance_of(RDF::Graph)
        expect(result).not_to be_empty
      end
    end

  end

  describe "#merge_ext_templates" do
    context "given three ids" do
      it "returns one template per id provided" do
        in_templates = [{'@id' => 'http://example.com/foo'},
                        {'@id' => 'http://example.com/bar'},
                        {'@id' => 'http://example.com/baz'}]
        external_templates = RDF::Graph.new
        result = CandidateSmasher.merge_external_templates( in_templates, external_templates )
        expect(result.subjects.count).to eq(3)
      end
    end

    context "given no ids" do
      it "returns an empty graph" do
        in_templates = Array.new
        external_templates = RDF::Graph.new
        result = CandidateSmasher.merge_external_templates( in_templates, external_templates )
        expect(result).to be_instance_of(RDF::Graph)
        expect(result.subjects.count).to eq(0)
      end
    end
  end

  describe "#make_candidate" do
    let(:performer) { {"@id" => "http://example.com/P1",
                       "name" => "foo" } }
    let(:template) { {"@id" => "http://example.com/T1",
                       "colors" => "4" } }

    it "assigns a random id using application prefix and hash" do
      c = CandidateSmasher.make_candidate( template, performer )
      prefix = CandidateSmasher::ID_PREFIX
      expect(c["@id"]).to match(/^#{prefix}[a-f0-9]{32}$/)
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

    context "with external templates" do
      it "returns candidates with attributes of performer and template" do
        cands = smasher_ext_tmpl.generate_candidates
        expect( cands.all?{|c| c.has_key? HAS_DISPOSITION_IRI } )
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
      it "returns candidates with attributes of performer and template" do
        result = smasher_ext_tmpl.smash!
        candidates = JSON.parse(result)[CandidateSmasher::HAS_CANDIDATE_IRI]
        expect( candidates.all?{|c| c.has_key? HAS_DISPOSITION_IRI} )
      end
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
