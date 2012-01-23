require 'rubygems'
require 'bundler'
Bundler.setup

require 'ffi-rzmq'
require 'spdy'
require 'em-zeromq'
require './lib/worker'

require 'goliath/goliath'
require 'goliath/runner'
require 'goliath/api'

require './router'

BROKER_TO_FRONTEND = 'tcp://localhost:5559'
BROKER_TO_WORKER = 'tcp://localhost:5560'
INCOMING_HTTP_PORT = 9000

context = ZMQ::Context.new

Thread.abort_on_exception = true

class Broker
  def run(ctx)
    frontend = ctx.socket(ZMQ::ROUTER)
    backend = ctx.socket(ZMQ::DEALER)

    frontend.bind(BROKER_TO_FRONTEND)
    backend.bind(BROKER_TO_WORKER)
    puts "Starting broker #{BROKER_TO_FRONTEND} => #{BROKER_TO_WORKER}"
    ZMQ::Device.new(ZMQ::QUEUE, frontend, backend)
  end
end

class HelloWorld < Worker
  def response(head, body)
    p [:HELLO_WORLD, head, body]
    @worker_identity = 'lol'

    [200, {'X-ZMQ' => @worker_identity}, "Hello from #{@worker_identity}"]
  end
end

# Start background threads (these could also be on different processes/boxes)
broker = Thread.new{ Broker.new.run(context) }
Thread.new{ HelloWorld.new({:route => BROKER_TO_WORKER}).run }


puts "Starting HTTP router on http://0.0.0.0:#{INCOMING_HTTP_PORT}"
api = Router.new
runner = Goliath::Runner.new(%w(-sv -c config/router.rb -p) << INCOMING_HTTP_PORT.to_s, api)
runner.app = Goliath::Rack::Builder.build(Router, api)
runner.run