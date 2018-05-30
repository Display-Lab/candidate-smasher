require './lib/candidate_smasher'

RSpec.describe CandidateSmasher do

  describe "#valid?" do

    # a la carte json components of spek
    let(:type)  {'"@type": "http://purl.obolibrary.org/obo/fio#SPEK"'}
    let(:bad_type)  {'"@type": "http://example.com/not/a/spek"'}
    let(:attr1) {'"http://purl.obolibrary.org/obo/fio#HasPerformer": []'}
    let(:attr2) {'"http://purl.obolibrary.org/obo/fio#UsesTemplate": []'}
    let(:attr3) {'"http://purl.obolibrary.org/obo/fio#UsesISR": []'}

    let(:full)    { "{#{type}, #{attr1}, #{attr2}, #{attr3}}" }
    let(:no_type) { "{#{attr1}, #{attr2}, #{attr3}}" }
    let(:not_spek)    { "{#{bad_type}, #{attr1}, #{attr2}, #{attr3}}" }
    let(:missing_attr)    { "{#{type}, #{attr1}, #{attr3}}" }

    it "is invalid when content is invalid json" do
      cs = CandidateSmasher.new("{}}")
      expect(cs.valid?).to be(false)
    end

    it "requires @type property" do
      cs = CandidateSmasher.new(no_type)
      expect(cs.valid?).to be(false)
    end

    it "requires @type property is spek" do
      cs = CandidateSmasher.new(not_spek)
      expect(cs.valid?).to be(false)
    end

    it "checks for required attributes" do
      cs = CandidateSmasher.new(missing_attr)
      expect(cs.valid?).to be(false)
    end

    it "is valid when required attributes are present" do
      cs = CandidateSmasher.new(full)
      expect(cs.valid?).to be(true)
    end

  end

  describe "#generate_candidates" do
    it "adds candidates to the spek" do
    end

    it "adds candidates to the spek" do
    end

  end
end
