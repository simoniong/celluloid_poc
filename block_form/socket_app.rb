require "reel"

Reel::Server::HTTP.run("0.0.0.0", 3000) do |connection|
  connection.each_request do |request|
    # WebSocket support
    if request.websocket?
      puts "Client made a WebSocket request to: #{request.url}"
      websocket = request.websocket

      websocket << "Hello everyone out there in WebSocket land"
      websocket.close
    else
      puts "Client requested: #{request.method} #{request.url}"
      request.respond :ok, "Hello, world!"
    end
  end
end
