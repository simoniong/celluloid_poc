require 'rubygems'
require 'bundler/setup'
require 'celluloid/autostart'
require 'reel'

POOL_SIZE = 1000
class SocketHandler
  include Celluloid
  include Celluloid::Logger

  def handle(socket)
    while true do
      msg = socket.read
      info "got msg: #{msg}"

      if msg == 'stop'
        socket.close
        break
      else
        info 'echo back'
        socket << "echo back: #{msg}"
        info 'done'
      end
    end
  rescue
    info 'client disconnect somehow'
    socket.close
  end

  def notify_rolling_restart
    info 'notify rolling restart inside actor'
  end
end

class MyServer < Reel::Server::HTTP
  include Celluloid::Logger

  def initialize(host = "127.0.0.1", port = 3000)
    super(host, port, &method(:on_connection))
    @pool = SocketHandler.pool(size: POOL_SIZE)
    @connection = []
    @flag = 'normal'
  end

  def normal?
    @flag == 'normal'
  end

  def restarting?
    @flag == 'restarting'
  end

  def notify_rolling_restart
    info 'got SIGTERM'
    @flag = 'restarting'

    @connection.each do |socket|
      info 'notify rolling restart'
      # TODO: connection should be abstract as a class
      socket << "notify rolling restart"
    end
    info 'done notify rolling restart'
  end

  def on_connection(connection)
    connection.each_request do |request|
      info 'running each_request'
      if request.websocket?
        socket = request.websocket
        @connection << socket

        socket << "welcome to socket world"
        @pool.handle socket
        info 'finished handling websocket'
      else
        handle_request(request)
      end
    end
  end

  def handle_request(request)
    request.respond :ok, "Hello, world!"
  end
end

MyServer.supervise_as :server
Signal.trap('SIGTERM') do
  Thread.new do
    Celluloid::Actor[:server].notify_rolling_restart
  end
end

sleep
