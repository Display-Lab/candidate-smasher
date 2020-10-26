require 'json'
require './lib/candidate_smasher'
require './lib/candidate_smasher_constants'
require './spec/graph_helpers'
require 'pry'

RSpec.configure do |c|
  c.include GraphHelpers
  CSC ||= CandidateSmasherConstants
end

RSpec.describe CandidateSmasher do
  let(:base_content) do
    { "@type" => CSC::SPEK_IRI,
      CSC::HAS_PERFORMER_IRI=> [
        {"@id" => "_:p1",
          CSC::HAS_DISPOSITION_IRI => [
            {"@type": "promotion_focus",
             CSC::REGARDING_MEASURE => {"@id" => "_:m1"}}
          ]
        },
        {"@id" => "_:p2",
          CSC::HAS_DISPOSITION_IRI => [
            {"@type" => "prevention_focus",
             CSC::REGARDING_MEASURE => {"@id" => "_:m1" }},
            {"@type" => "positive_trend",
             CSC::REGARDING_MEASURE => {"@id" => "_:m1" }}
          ]
        },
        {"@id" => "_:p3",
          CSC::HAS_DISPOSITION_IRI => [
            {"@type" => "prevention_focus", 
             CSC::REGARDING_MEASURE => {"@id" => "_:m1" }},
            {"@type" => "positive_trend",   
             CSC::REGARDING_MEASURE => {"@id" => "_:m1" }},
            {"@type" => "promotion_focus",  
             CSC::REGARDING_MEASURE => {"@id" => "_:m2" }},
            {"@type" => "negative_trend",   
             CSC::REGARDING_MEASURE => {"@id" => "_:m2" }}
          ]
        } 
      ],
      CSC::ABOUT_TEMPLATE_IRI => [
        {"@id" => "https://inferences.es/app/onto#TPLT001"},
        {"@id" => "https://inferences.es/app/onto#TPLT002"},
        {"@id" => "https://inferences.es/app/onto#TPLT003"} ],
      CSC::USES_ISR_IRI => [] 
    }
  end

  let(:comparator_one) do 
    {"@id" => "_:m1000", "@type" => "social_comparator"}
  end

  let(:comparator_two) do 
    {"@id" => "_:m2000", "@type" => "goal_comparator"}
  end

  let(:blank_content) do { "@type" => CSC::SPEK_IRI,
          CSC::HAS_PERFORMER_IRI=> [],
          CSC::ABOUT_TEMPLATE_IRI => [],
          CSC::USES_ISR_IRI => [] }
  end

  let(:ext_template_content) do
    {
      "@graph" => [
        {
          "@id"   => "https://inferences.es/app/onto#TPLT001",
          "@type" => "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
          CSC::IS_ABOUT => [
            {"@type": "http://purl.obolibrary.org/obo/psdo_0000117"},
            {"@type": "http://purl.obolibrary.org/obo/psdo_0000045"},
            {"@type": "http://purl.obolibrary.org/obo/psdo_0000041"}
          ]
        },
        {
          "@id" => "https://inferences.es/app/onto#TPLT002",
          "@type" => "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
          CSC::IS_ABOUT => [
            {"@type": "http://example.com/foo"},
            {"@type": "http://example.com/bar"}
          ]
        },
        {
          "@id" => "https://inferences.es/app/onto#TPLT003",
          "@type" => "http://purl.obolibrary.org/obo/psdo#psdo_0000002",
          CSC::IS_ABOUT => [ {"@type": "http://example.com/foo"} ]
        }, 
        {
          "@id" => "https://inferences.es/app/onto#TPLT004",
          "@type" => "http://purl.obolibrary.org/obo/psdo#psdo_0000002"
        } 
      ]
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

  let(:smasher_comps) do
    c = CandidateSmasher.new 

    # deep copy base content
    c.spek_hsh = Marshal.load(Marshal.dump(base_content))
    # Add comparators
    disps = c.spek_hsh[CSC::HAS_PERFORMER_IRI][2][CSC::HAS_DISPOSITION_IRI]
    disps[2][CSC::REGARDING_COMPARATOR] = comparator_one
    disps[3][CSC::REGARDING_COMPARATOR] = comparator_two

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

      it "requires spek to have performers" do
        smasher_blank.spek_hsh.delete(CSC::HAS_PERFORMER_IRI)
        expect(smasher_blank.valid?).to be(false)
      end

      it "requires spek to have templates" do
        smasher_blank.spek_hsh.delete(CSC::ABOUT_TEMPLATE_IRI)
        expect(smasher_blank.valid?).to be(false)
      end

      it "allows external templates as substitute for spek templates" do
        smasher_blank.spek_hsh.delete(CSC::ABOUT_TEMPLATE_IRI)
        smasher_blank.template_lib = {foo_iri: "ex", bar_iri: "ex"}
        expect(smasher_blank.valid?).to be(true)
      end

      it "is valid when required attributes are present" do
        expect(smasher_blank.valid?).to be(true)
      end
    end
  end

  describe "#list_missing" do
    it "returns clues about failed validity checks." do
      smasher_blank.spek_hsh.delete(CSC::ABOUT_TEMPLATE_IRI)
      smasher_blank.spek_hsh.delete(CSC::HAS_PERFORMER_IRI)
      smasher_blank.spek_hsh.delete("@type")
      expect(smasher_blank.list_missing.length == 3)
    end
  end

  describe "#load_ext_templates" do
    context"with no external template metadata" do
      it "returns empty hash" do
        result = smasher_blank.load_ext_templates(nil)
        expect(result).to be_instance_of(Hash).and be_empty
      end
    end

    context"using external template metadata" do
      it "returns hash representation" do
        fixture_file = 'spec/fixtures/templates-metadata.json'
        result = smasher_blank.load_ext_templates(fixture_file)

        expect(result).to be_instance_of(Hash)
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
        external_templates = {}
        result = CandidateSmasher.merge_external_templates( in_templates, external_templates )
        expect(result.length).to eq(3)
      end
    end

    context "given no ids" do
      it "returns an empty array" do
        in_templates = Array.new
        external_templates = RDF::Graph.new
        result = CandidateSmasher.merge_external_templates( in_templates, external_templates )
        expect(result).to be_instance_of(Array)
        expect(result.length).to eq(0)
      end
    end

    #TODO implement test that checks external triples are included.
    it "merges tripples from external templates" do
      skip "defining what result should look like"

    end

    it "only takes given ids from external templates" do
      skip "defining what result should look like"

    end

  end

  describe "#make_candidate" do
    let(:performer) { {"@id" => "http://example.com/P1",
                       "name" => "foo" } }
    let(:template) { {"@id" => "http://example.com/T1",
                       "colors" => "4" } }

    it "assigns a random id using application prefix and hash" do
      c = CandidateSmasher.make_candidate( template, performer )
      prefix = CSC::ID_PREFIX
      expect(c["@id"]).to match(/^#{prefix}[a-f0-9]{32}$/)
    end
    
    it "assigns the candidate type" do
      c = CandidateSmasher.make_candidate( template, performer )
      expect(c["@type"]).to eq(CSC::CANDIDATE_IRI)
    end

    it "retains ancestor ids" do
      c = CandidateSmasher.make_candidate( template, performer )
      expect(c[CSC::ANCESTOR_PERFORMER_IRI]).to eq(performer["@id"])
      expect(c[CSC::ANCESTOR_TEMPLATE_IRI]).to eq(template["@id"])
    end

  end

  describe "#generate_candidates" do
    context "with empty content" do
      it "returns empty" do
        expect(smasher_empty.generate_candidates).to be_empty
      end
    end

    context "with multiple content" do
      it "returns candidates with unique ids" do
        cands = smasher_base.generate_candidates
        uniq_ids = cands.map{|c|c["@id"]}.uniq

        expect(uniq_ids.length).to be(cands.length)
      end

      it "has expected number of candidates when no comparators specified." do
        # is num of templates x num of performer-measure-comparators
        num_templates = smasher_base.spek_hsh[CSC::ABOUT_TEMPLATE_IRI].length

        performers = smasher_base.spek_hsh[CSC::HAS_PERFORMER_IRI]
        pmc_total = count_disposition_groups(performers)
        expected_candidate_count = num_templates * pmc_total

        cands = smasher_base.generate_candidates
        expect(cands.length).to eq(expected_candidate_count)
      end

      it "has expecte number of candidates when comparators present." do
        smasher_comps

        num_templates = smasher_comps.spek_hsh[CSC::ABOUT_TEMPLATE_IRI].length

        performers = smasher_comps.spek_hsh[CSC::HAS_PERFORMER_IRI]
        pmc_total = count_disposition_groups(performers)
        expected_candidate_count = num_templates * pmc_total

        cands = smasher_comps.generate_candidates
        expect(cands.length).to eq(expected_candidate_count)
      end
    end

    context "with external templates" do
      it "returns candidates with attributes of performer and template" do
        cands = smasher_ext_tmpl.generate_candidates
        expect( cands.all?{|c| c.has_key? CSC::HAS_DISPOSITION_IRI } )
      end

      it "returns only candidates in spek " do
        cands = smasher_ext_tmpl.generate_candidates
        ancestor_template_ids = cands.map{|c| c[CSC::ANCESTOR_TEMPLATE_IRI]}.uniq
        spek_template_ids = smasher_ext_tmpl.spek_hsh[CSC::ABOUT_TEMPLATE_IRI].map{|t| t["@id"]}.uniq

        expect(ancestor_template_ids).to match_array spek_template_ids
      end
    end
  end

  describe "#smash!" do
    context "with empty content" do
      it "adds candidates to the spek" do
        smasher_empty.smash!
        expect(smasher_empty.spek_hsh.has_key?(CSC::HAS_CANDIDATE_IRI)).to be(true)
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
        candidates = JSON.parse(result)[CSC::HAS_CANDIDATE_IRI]
        expect( candidates.all?{|c| c.has_key? CSC::HAS_DISPOSITION_IRI} )
      end
    end

    context "with multiple content" do
      it "adds candidates to the spek" do
        smasher_base.smash!
        expect(smasher_base.spek_hsh.has_key?(CSC::HAS_CANDIDATE_IRI)).to be(true)
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
