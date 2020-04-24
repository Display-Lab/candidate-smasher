require './lib/candidate_smasher'
require './lib/candidate_smasher_constants'
require './spec/graph_helpers'
require 'json'
require 'pry'

RSpec.configure do |c|
  CSC ||= CandidateSmasherConstants
  # Specify fixture location
  # config.file_fixture_path = "spec/fixtures"
end


RSpec.describe CandidateSmasher do
  let(:aspire_small_content) do
    File.read("spec/fixtures/aspire_small_spek.json")
  end

  let(:aspire_smasher) do
    CandidateSmasher.new(aspire_small_content)
  end

  it "has correct number of candidates" do
    cands = aspire_smasher.generate_candidates
    expect(cands.length).to eq(8)
  end

  it "candidates all have unique ids" do
    cands    = aspire_smasher.generate_candidates
    uniq_ids = cands.map{|c|c["@id"]}.uniq
    expect(uniq_ids.length).to eq(cands.length)
  end
end
