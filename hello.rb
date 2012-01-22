require './lib/worker'

class HelloWorld < Worker
  def response(head, body)
    p [:HELLO_WORLD, head, body]
    @worker_identity = 'lol'

    [200, {'X-ZMQ' => @worker_identity}, "Hello from #{@worker_identity}"]
  end
end

puts "Starting worker: #{ARGV[0]}"
w = HelloWorld.new({:route => 'tcp://localhost:5560'})
w.run