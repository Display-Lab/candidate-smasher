module GraphHelpers
  def json_to_graph(json_string)
    reader = JSON::LD::Reader.new(input=json_string)
    graph = RDF::Graph.new
    graph.insert_statements reader
    return graph
  end

  # Count unique measure-comparator combinations for all performer
  def count_disposition_groups(performers)
    performers.map do |p|
      p[CandidateSmasher::HAS_DISPOSITION_IRI].map do |d|
        m_id = d.dig(CandidateSmasher::REGARDING_MEASURE,'@id')
        c_id = d.dig(CandidateSmasher::REGARDING_COMPARATOR,'@id')
        (m_id || "") + (c_id || "")
      end.uniq.length
    end.sum
  end
end
