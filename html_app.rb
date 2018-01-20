require 'reel'

Reel::Server::HTTP.run('127.0.0.1', 3000) do |connection|
  connection.each_request do |request|
    request.respond :ok, "hello, world!"
  end
end
