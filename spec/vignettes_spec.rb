require 'json'
require './lib/candidate_smasher'
require './lib/candidate_smasher_constants'
require './spec/graph_helpers'
require 'pry'

RSpec.configure do |c|
  c.include GraphHelpers
  CSC ||= CandidateSmasherConstants
end

# Alice Template attributes
#    "PositivePerformanceGapSet":       "http://purl.obolibrary.org/obo/psdo_0000117",
#    "psdo-RecipientElement":                "http://purl.obolibrary.org/obo/psdo_0000041",
#    "psdo-SocialComparatorElement":         "http://purl.obolibrary.org/obo/psdo_0000045",

VIGNETTE_DIR = File.join(File.dirname(__FILE__), 'fixtures', 'vignettes')
ALICE_SPEK_PATH = File.join(VIGNETTE_DIR, "alice_spek.json")
ALICE_TMPL_PATH = File.join(VIGNETTE_DIR, "alice_templates.json")

context('Using vignette example from VRA project') do
  let(:spek_content){ File.open(ALICE_SPEK_PATH){|f| f.read}}
  let(:tmpl_content){ File.open(ALICE_TMPL_PATH){|f| f.read}}
  let(:tmpl_hsh){JSON.parse tmpl_content}

  it "does not fail with spek only" do
    md_source = nil
    CandidateSmasher.new(spek_content, md_source).smash!
  end

  it "does not fail with spek and templates" do
    md_source = ALICE_TMPL_PATH
    CandidateSmasher.new(spek_content, md_source).smash!
  end

  it "adds template IS_ABOUT to HAS_DISPOSITION of every candidate", cwt: true do
    md_source = ALICE_TMPL_PATH
    updated_spek = JSON.parse CandidateSmasher.new(spek_content, md_source).smash!
    candidates = updated_spek[CSC::HAS_CANDIDATE_IRI]

    attrs = tmpl_hsh['@graph'].first[CSC::IS_ABOUT_IRI] || tmpl_hsh['@graph'].first['IAO-IsAbout']

    candidates.each do |cand| 
      #need to splat attrs as `include` wraps args into an array
      expect(cand[CSC::HAS_DISPOSITION_IRI]).to include(*attrs)
    end
  end

end
