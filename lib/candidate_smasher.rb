require "rdf"
require "json/ld"
require "digest"
require_relative 'candidate_smasher_constants'

class CandidateSmasher

  include CandidateSmasherConstants

  attr_accessor :spek_hsh
  
  def initialize(input_string="{}")
    begin
      @spek_hsh = JSON.parse input_string
    rescue JSON::ParserError
      @spek_hsh = Hash.new
    end

  end

  def valid?
    checks().values.all?{|c| c}
  end

  def checks
    {"@type": @spek_hsh["@type"] == SPEK_IRI, 
     "#{HAS_PERFORMER_IRI}": @spek_hsh.has_key?(HAS_PERFORMER_IRI)} 
  end

  def list_missing
    checks().select{|k,v| !v}.keys
  end


  def split_by_disposition_attr(performer, attr_uri)
    dispositions = performer[HAS_DISPOSITION_IRI]
    return [performer] if dispositions.nil?

    uniques = dispositions.map{|d| d[attr_uri]}.uniq
    splits = uniques.map do |attr|
      p = performer.dup
      p[HAS_DISPOSITION_IRI] = dispositions.select do |d|
        d[attr_uri] == attr
      end
      p
    end
    return splits
  end

  def split_by_measure(performer)
    split_by_disposition_attr(performer, REGARDING_MEASURE)
  end

  def split_by_comparator(performer)
    split_by_disposition_attr(performer, REGARDING_COMPARATOR)
  end

  def generate_candidates
    performers = @spek_hsh[HAS_PERFORMER_IRI] || Array.new
    # Split by measure then by comparator
    pm_split = performers.map{|p| split_by_measure(p)}.flatten(1)
    pmc_split = pm_split.map{|pm| split_by_comparator(pm)}.flatten(1)


    res = pmc_split.collect do |p|
      CandidateSmasher.make_candidate(p) 
    end
    res.flatten
  end

  def smash!
    pavers = generate_candidates
    @spek_hsh[HAS_PAVER_IRI] = pavers
    JSON.dump(@spek_hsh)
  end

  # Get the first measure from the dispositions
  #   Hack to help make unique ids after split by measure 
  def self.regarding_measure(split_performer)
    dispositions = split_performer[HAS_DISPOSITION_IRI]
    if dispositions.nil? || dispositions.empty?
      return ""
    end
    disp = dispositions.first
    disp.dig(REGARDING_MEASURE,"@id") || ""
  end

  # Hack to help make unique ids after split by comparator 
  def self.regarding_comparator(split_performer)
    dispositions = split_performer[HAS_DISPOSITION_IRI]
    if dispositions.nil? || dispositions.empty?
      return ""
    end
    disp = dispositions.first
    disp.dig(REGARDING_COMPARATOR,"@id") || ""
  end

  # split performer is one with only relevant dispositions present
  def self.make_candidate(split_performer)
    p_id = split_performer["@id"]
    m_id = regarding_measure(split_performer)
    c_id = regarding_comparator(split_performer)

    candidate = split_performer.slice(HAS_DISPOSITION_IRI)
    candidate["@type"] = PAVER_IRI
    candidate["@id"] = ID_PREFIX + Digest::MD5.hexdigest("#{p_id}#{m_id}#{c_id}")
    candidate[ANCESTOR_PERFORMER_IRI] = p_id

    return(candidate)
  end
end
