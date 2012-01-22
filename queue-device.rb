require 'rubygems'
require 'ffi-rzmq'

context = ZMQ::Context.new
frontend = context.socket(ZMQ::ROUTER)
backend = context.socket(ZMQ::DEALER)

frontend.bind('tcp://*:8001')
backend.bind('tcp://*:8000')


ZMQ::Device.new(ZMQ::QUEUE, frontend, backend)