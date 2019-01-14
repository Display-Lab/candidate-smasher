require "rdf"
require "json/ld"
require "digest"

class CandidateSmasher
  ID_PREFIX              = "http://example.com/app#"
  SPEK_IRI               = "http://example.com/slowmo#slowmo_0000140"
  HAS_PERFORMER_IRI      = "http://example.com/slowmo#slowmo_0000001"
  USES_TEMPLATE_IRI      = "http://example.com/slowmo#slowmo_0000003"
  USES_ISR_IRI           = "http://example.com/slowmo#slowmo_0000002"
  ANCESTOR_PERFORMER_IRI = "http://example.com/slowmo#AncestorPerformer"
  ANCESTOR_TEMPLATE_IRI  = "http://example.com/slowmo#AncestorTemplate"
  CANDIDATE_IRI          = "http://example.com/cpo#cpo_0000053"
  HAS_CANDIDATE_IRI      = "http://example.com/slowmo#hasCandidate"
  TEMPLATE_CLASS_IRI     = "http://purl.obolibrary.org/obo/psdo#psdo_0000002"

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
    checks = [@spek_hsh["@type"] == SPEK_IRI,
              @spek_hsh.has_key?(HAS_PERFORMER_IRI),
              @spek_hsh.has_key?(USES_TEMPLATE_IRI),
              @spek_hsh.has_key?(USES_ISR_IRI)]
    checks.all?{|c| c}
  end

  def load_ext_templates(templates_src)
    if templates_src.nil?
      RDF::Graph.new
    else
      RDF::Graph.load(templates_src)
    end
  end

  # Given JSON templates from spec, merge graph of statements from external templates library
  def self.merge_external_templates(spec_templates, ext_templates)
    template_ids = spec_templates.collect { |t| RDF::URI t['@id'] }

    statements = template_ids.collect do |id|
      RDF::Statement.new(id, RDF.type, RDF::URI(TEMPLATE_CLASS_IRI) )
    end

    template_ids.each do |id|
      query = RDF::Query.new { pattern [id, :pred, :obj] }

      solutions = query.execute ext_templates
      solutions.each do |solution|
        statements << RDF::Statement.new(id, solution.pred, solution.obj) 
      end
    end
    
    g = RDF::Graph.new
    g.insert_statements statements
    g
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

  def generate_candidates
    performers = @spek_hsh[HAS_PERFORMER_IRI] || Array.new
    spec_templates = @spek_hsh[USES_TEMPLATE_IRI] || Array.new

    rdf_templates = CandidateSmasher.merge_external_templates(spec_templates, @template_lib) 

    templates = templates_rdf_to_json rdf_templates

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
    candidate["@id"] = ID_PREFIX + Digest::MD5.hexdigest(t_id + p_id)
    candidate[ANCESTOR_PERFORMER_IRI] = p_id
    candidate[ANCESTOR_TEMPLATE_IRI]  = t_id

    return(candidate)
  end
end
