require 'rubygems'
require 'bundler/setup'
require 'reel'
require 'json'
require 'celluloid/autostart'

POOL_SIZE = 2
require_relative './lib/game_backend'
require_relative './lib/socket_handler'

class WebServer < Reel::Server::HTTP
  include Celluloid::Logger

  def initialize(host = "127.0.0.1", port = 3000)
    info "Server starting on #{host}:#{port}"
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    request = connection.request
    if request.websocket?
      info "Received a WebSocket connection"
      socket = request.websocket
      socket << "welcome to socket world!"
      route_websocket socket
    else
      route_request connection, request
    end
  end

  def route_request(connection, request)
    info "404 Not Found: #{request.path}"
    connection.respond :not_found, "Not found"
  end

  def route_websocket(socket)
    SocketHandler.new(socket)
  end
end

GameBackend.supervise_as :game_backend
WebServer.supervise_as :web

sleep
