
#require 'rubygems'
# $: << '/git/spdy/lib'
#
#require 'bundler'
#Bundler.require


class Worker
  def initialize(opts = {})
    @worker_identity = opts[:identity]

    ctx = ZMQ::Context.new(1)
    @conn = ctx.socket(ZMQ::DEALER)
    @conn.connect(opts[:route])

    @stream_id = nil
    @headers = {}
    @body = ''

    @p = SPDY::Parser.new

    @p.on_open do |stream, astream, priority|
      @stream_id = stream
    end

    @p.on_body do |stream, body|
      @body << body
    end

    @p.on_headers do |stream,  head|
      @headers.merge! head
    end

    @p.on_message_complete do |stream|
      status, head, body = response(@headers, @body)

      synreply = SPDY::Protocol::Control::SynReply.new
      headers = {'status' => status.to_s, 'version' => 'HTTP/1.1'}.merge(head)
      synreply.create(:stream_id => @stream_id, :headers => headers, :flags => SPDY::Protocol::FLAG_NOCOMPRESS)

      send [synreply.to_binary_s]

      # Send body & close connection
      resp = SPDY::Protocol::Data::Frame.new
      resp.create(:stream_id => @stream_id, :flags => 1, :data => body)
      puts resp.to_binary_s.inspect

      send [resp.to_binary_s]
      
      puts "Response away"
    end
  end

  def send(data_parts)
    parts = @envelopes + [''] + data_parts
    puts "sending #{parts.inspect}"
    @conn.send_strings(parts)
  end

  def run
    loop do
      poller = ZMQ::Poller.new
      poller.register(@conn, ZMQ::POLLIN)

      poller.poll(:blocking)

      in_envelope = true

      @envelopes = []

      loop do
        @conn.recv_string(part = '')

        if in_envelope
          @envelopes << part
        else
          puts "got part: #{part.inspect}"
          @p << part
        end

        in_envelope = false if part == ''
        break unless @conn.more_parts?
      end
    end
  end

end