require "json/ld"

class CandidateSmasher
  SPEK_IRI = "http://purl.obolibrary.org/obo/fio#SPEK"
  HAS_PERFORMER_IRI= "http://purl.obolibrary.org/obo/fio#HasPerformer"
  USES_TEMPLATE_IRI = "http://purl.obolibrary.org/obo/fio#UsesTemplate"
  USES_ISR_IRI = "http://purl.obolibrary.org/obo/fio#UsesISR"

  attr_reader :spek_hsh
  
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

  def generate_candiates

  end
end
