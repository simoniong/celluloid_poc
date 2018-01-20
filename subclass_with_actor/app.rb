require 'rubygems'
require 'bundler/setup'
require 'celluloid/autostart'
require 'reel'

class MyConnectionHandler
  include Celluloid
  include Celluloid::Logger

  def initialize(connection)
    info 'bypass connection to MyConnectionHandler'
    @connection = connection
    async.run
  rescue Reel::SocketError
    @connection.close
  end

  def run
    @connection.each_request { |req| handle_request(req) }
  end

  def handle_request(request)
    info 'handle incoming request'
    if request.websocket?
      handle_websocket(request.websocket)
    else
      handle_http(request)
    end
  end

  def handle_http(request)
    request.respond :ok, "Hello, world!"
  end

  def handle_websocket(sock)
    sock << "Hello everyone out there in WebSocket land!"
    sock.close
  end
end

class MyServer < Reel::Server::HTTP
  def initialize(host = "127.0.0.1", port = 3000)
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    connection.detach
    MyConnectionHandler.new(connection)
  end
end

MyServer.run
