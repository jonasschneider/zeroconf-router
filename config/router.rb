@router = {}

config['stream'] = 1
config['identity'] = 'http-spdy-bridge'
config['router'] = @router

Thread.abort_on_exception = true
config['ctx'] = EM::ZeroMQ::Context.new(1)

class XREQHandler

  def initialize(router)
    @router = router
    @p = SPDY::Parser.new

    @p.on_headers do |stream, head|
      p [:HEADERS, :stream, stream, :headers, head]

      status = head.delete('status')
      version = head.delete('version')

      headers  = "#{version} #{status}\r\n"
      head.each do |k,v|
        headers << "%s: %s\r\n" % [k.capitalize, v]
      end

      # emit HTTP headers generated by ZMQ worker
      @router[stream].stream_send(headers + "\r\n")
    end

    @p.on_body do |stream, data|
      p [:ZMQ_BODY, stream, data]

      # emit data chunk generated by ZMQ worker
      @router[stream].stream_send data
    end

    @p.on_message_complete do |stream|
      p [:ZMQ_FIN, stream]

      # terminate connection when ZMQ worker sends a FIN flag
      @router[stream].stream_close
      @router.delete stream
    end
  end

  def on_readable(socket, messages)
    messages.each do |m|
      #puts "got: #{m.copy_out_string.inspect}"
      @p << m.copy_out_string
    end
  end
end

config['handler'] = XREQHandler.new(@router)

puts "Bound XREQ handler to port 8000, let the games begin!"
