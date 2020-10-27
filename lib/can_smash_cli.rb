require "thor"
require "pry"
require_relative "candidate_smasher"
require_relative "input_resolver"
 
class CanSmashCLI < Thor
  class_option :path, :type => :string, :banner => "path to spek file."
  class_option :md_source, :type => :string, :banner => "URI to template metadata source."

  default_task :generate

  desc "generate", "The main function"
  def generate(path=nil)
    path ||= options[:path]
    md_source = options[:md_source]

    begin
      input = InputResolver.resolve path
      content = input.read
    rescue InputResolver::InputError => myex
      STDERR.puts(myex)
      exit(1)
    end

    #metadata = read_metadata md_source

    cs = CandidateSmasher.new(content, md_source)
    if cs.valid?
      puts cs.smash!
    else
      abort("Invalid input spec. Missing/Bad: #{cs.list_missing}")
    end
  end

  private

  def self.exit_on_failure?
    true
  end
end
