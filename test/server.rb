# author: Oleg Sidorov <4pcbr> i4pcbr@gmail.com
# this code is licenced under the MIT/X11 licence.
require 'rubygems'
require 'bundler'
Bundler.require

context = ZMQ::Context.new
socket = context.socket(ZMQ::DEALER)
socket.connect('tcp://localhost:5560')

# Initialize a poll set
poller = ZMQ::Poller.new
poller.register(socket, ZMQ::POLLIN)

loop do
  poller.poll(:blocking)
 
  parts = []
  loop do
    socket.recv_string(message = '')
    parts << message
    break unless socket.more_parts?
  end

  puts parts.inspect
  ident = parts.first
  msg = parts.last
 
  socket.send_string(ident, ZMQ::SNDMORE)
  socket.send_string("", ZMQ::SNDMORE)
  socket.send_string("lolz1: #{msg}")

  socket.send_string(ident, ZMQ::SNDMORE)
  socket.send_string("", ZMQ::SNDMORE)
  socket.send_string("lolz2: #{msg}")
end