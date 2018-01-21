require 'rubygems'
require 'bundler/setup'
require 'celluloid/autostart'
require 'reel'

class MyServer < Reel::Server::HTTP
  include Celluloid::Logger

  def initialize(host = "127.0.0.1", port = 3000)
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    connection.each_request do |request|
      if request.websocket?
        handle_websocket(request.websocket)
      else
        handle_request(request)
      end
    end
  end

  def handle_request(request)
    request.respond :ok, "Hello, world!"
  end

  def handle_websocket(sock)
    sock << "Hello everyone out there in WebSocket land!"
    msg = sock.read
    info "got msg: #{msg}"
    sock << "echo back: #{msg}"
    sock.close
  end
end

MyServer.run
