require_relative "input_error"

class InputResolver
  def self.resolve(path)
    if(path.nil?)
      input_method = $stdin
    elsif(File.exists?(path) && File.readable?(path))
      input_method = File.open(path, mode="r") 
    else
      raise InputError.new("Bad input path")
    end
  end
end
