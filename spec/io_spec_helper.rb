require 'stringio'
require 'pry'

# From https://tommaso.pavese.me/2016/05/08/understanding-and-testing-io-in-ruby/
module IoSpecHelper
  def simulate_stdin(*inputs, &block)
    io = StringIO.new
    inputs.flatten.each { |str| io.write(str) }
    io.rewind

    actual_stdin, $stdin = $stdin, io
    yield
  ensure
    $stdin = actual_stdin
  end
end
