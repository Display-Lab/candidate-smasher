require "json/ld"
require "digest"

class CandidateSmasher
  SPEK_IRI = "http://purl.obolibrary.org/obo/fio#SPEK"
  HAS_PERFORMER_IRI= "http://purl.obolibrary.org/obo/fio#HasPerformer"
  USES_TEMPLATE_IRI = "http://purl.obolibrary.org/obo/fio#UsesTemplate"
  USES_ISR_IRI = "http://purl.obolibrary.org/obo/fio#UsesISR"
  ANCESTOR_PERFORMER_IRI = "http://purl.obolibrary.org/obo/fio#AncestorPerformer"
  ANCESTOR_TEMPLATE_IRI = "http://purl.obolibrary.org/obo/fio#AncestorTemplate"
  CANDIDATE_IRI = "http://purl.obolibrary.org/obo/fio#Candidate"
  HAS_CANDIDATE_IRI = "http://purl.obolibrary.org/obo/fio#hasCandidate"

  attr_accessor :spek_hsh
  
  def initialize(input_string="{}")
    begin
      @spek_hsh = JSON.parse input_string
    rescue JSON::ParserError
      @spek_hsh = Hash.new
    end
  end

  def valid?
    checks = [@spek_hsh["@type"] == SPEK_IRI,
              @spek_hsh.has_key?(HAS_PERFORMER_IRI),
              @spek_hsh.has_key?(USES_TEMPLATE_IRI),
              @spek_hsh.has_key?(USES_ISR_IRI)]
    checks.all?{|c| c}
  end

  def generate_candidates
    performers = @spek_hsh[HAS_PERFORMER_IRI]
    templates = @spek_hsh[USES_TEMPLATE_IRI]

    res = performers.collect do |p|
      templates.collect{|t| CandidateSmasher.make_candidate(t,p) }
    end

    res.flatten
  end

  def smash!
    candidates = generate_candidates
    @spek_hsh[HAS_CANDIDATE_IRI] = candidates
    JSON.dump(@spek_hsh)
  end

  def self.make_candidate(template, performer)
    t_id = template["@id"]
    p_id = performer["@id"]

    candidate = template.merge performer
    candidate["@type"] = CANDIDATE_IRI
    candidate["@id"] = "candidate.internal/" + Digest::MD5.hexdigest(t_id + p_id)
    candidate[ANCESTOR_PERFORMER_IRI] = p_id
    candidate[ANCESTOR_TEMPLATE_IRI]  = t_id

    return(candidate)
  end
end
