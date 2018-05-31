require "thor"
require "pry"
require_relative "input_error"
require_relative "candidate_smasher"
 
class CanSmashCLI < Thor
  class_option :path, :type => :string, :banner => "path to spek file."
  class_option :md_source, :type => :string, :banner => "URI to template metadata source."

  default_task :generate

  desc "generate", "The main function"
  def generate(path=nil)
    path ||= options[:path]
    md_source = options[:md_source]

    begin
      input = resolve_input path
      content = input.read
    rescue InputError => myex
      STDERR.puts(myex)
      exit(1)
    end

    cs = CandidateSmasher.new content
    if cs.valid?
      puts cs.smash!
    else
      STDERR.puts("Invalid input")
      exit(1)
    end
  end

  private

  def resolve_input(path)
    if(path.nil?)
      input_method = $stdin
    elsif(File.exists?(path) && File.readable?(path))
      input_method = File.open(path, mode="r") 
    else
      raise InputError.new("Bad input path")
    end
  end
end
