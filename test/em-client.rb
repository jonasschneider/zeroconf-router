require 'rubygems'
require 'em-zeromq'

Thread.abort_on_exception = true

class EMTestPullHandler
  attr_reader :received
  def on_readable(socket, parts)
    delim, body = *parts.map{|p|p.copy_out_string}
    raise "delim should be empty" unless delim.empty?
    puts body
  end
end


ctx = EM::ZeroMQ::Context.new(1)

EM.run do
  req_socket = ctx.connect( ZMQ::DEALER, 'tcp://localhost:5559', EMTestPullHandler.new)

  n = 0

  # push_socket.hwm = 40
  # puts push_socket.hwm
  # puts pull_socket.hwm

  EM::PeriodicTimer.new(0.1) do
    puts '.'
    msg = "t#{n += 1}_"
    req_socket.send_msg('', msg)
  end
end