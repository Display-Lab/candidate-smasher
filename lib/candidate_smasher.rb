require "rdf"
require "json/ld"
require "digest"
require_relative 'candidate_smasher_constants'

class CandidateSmasher

  include CandidateSmasherConstants

  attr_accessor :spek_hsh, :template_lib
  
  def initialize(input_string="{}", templates_src=nil)
    begin
      @spek_hsh = JSON.parse input_string
    rescue JSON::ParserError
      @spek_hsh = Hash.new
    end

    @template_lib = load_ext_templates templates_src
  end

  def valid?
    checks().values.all?{|c| c}
  end

  def checks
    {"@type": @spek_hsh["@type"] == SPEK_IRI, 
     "#{HAS_PERFORMER_IRI}": @spek_hsh.has_key?(HAS_PERFORMER_IRI), 
     "#{ABOUT_TEMPLATE_IRI}": !@template_lib.empty? || @spek_hsh.has_key?(ABOUT_TEMPLATE_IRI)}
  end

  def list_missing
    checks().select{|k,v| !v}.keys
  end

  def load_ext_templates(templates_src)
    if templates_src.nil?
      Hash.new
    else
      File.open(templates_src){|file| JSON.load file}
    end
  end

  def load_ext_templates_rdf(templates_src)
    if templates_src.nil?
      RDF::Graph.new
    else
      RDF::Graph.load(templates_src)
    end
  end

  # Given JSON templates from spec, merge graph of statements from external templates library
  def self.merge_external_templates(spec_templates, ext_templates)
    t_ids = spec_templates.map{|t| t['@id']}

    # For every template in spec, lookup from external and merge info.
    merged = spec_templates.map do |t|
      new_t = ext_templates.select{|e| e['@id'] == t['@id']}.first || {}

      new_t.merge(t) do |key, ext_val, spek_val|
        if spek_val.is_a?(Array) || ext_val.is_a?(Array)
          result = Array(spek_val) + Array(ext_val)
          result.uniq
        else
          spek_val
        end
      end
    end

    merged
  end

  # interrim hack until everything is RDF from the get go
  def templates_rdf_to_json(graph)
    ld_tmpl = JSON::LD::API.fromRdf(graph).compact
    ld_tmpl.each do |template|
      template.transform_values! do |v|
        if(v.respond_to?(:first) && v.length == 1)
          v.first
        else
          v
        end
      end
    end
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

    spec_templates = @spek_hsh[ABOUT_TEMPLATE_IRI] || Array.new
    templates = CandidateSmasher.merge_external_templates(spec_templates, @template_lib) 

    res = pmc_split.collect do |p|
      templates.collect{|t| CandidateSmasher.make_candidate(t,p) }
    end
    res.flatten
  end

  def smash!
    candidates = generate_candidates
    @spek_hsh[HAS_CANDIDATE_IRI] = candidates
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

  def self.make_candidate(template, performer)
    t_id = template["@id"]
    p_id = performer["@id"]
    m_id = regarding_measure(performer)
    c_id = regarding_comparator(performer)

    candidate = template.merge performer
    candidate["@type"] = CANDIDATE_IRI
    candidate["@id"] = ID_PREFIX + Digest::MD5.hexdigest("#{t_id}#{p_id}#{m_id}#{c_id}")
    candidate[ANCESTOR_PERFORMER_IRI] = p_id
    candidate[ANCESTOR_TEMPLATE_IRI]  = t_id

    return(candidate)
  end
end
