class SocketHandler
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  def initialize(websocket)
    info "Streaming socket to socket handler"
    @socket = websocket
    reader = SocketReader.new(@socket)
    # NOTED:
    # we need to use async way with bang
    # so that this actor can continue to subscribe events
    reader.async.read
    subscribe('notify_response', :notify_response)
    subscribe('notify_restarting', :notify_restarting)
  end

  def notify_response(topic, payload)
    info "notify response with payload: #{payload}"
    write('response', payload)
  end

  def notify_with_response(topic, payload)
    info "notify restarting with payload: #{payload}"
    write('rolling_restart', payload)
  end

  def write(action, payload)
    @socket << JSON.generate({ action: action, payload: payload })
  rescue Reel::SocketError
    info "Client disconnected"
    terminate
  end

  class SocketReader
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications
    def initialize(socket)
      @socket = socket
    end

    def read
      while true do
        message = @socket.read
        info "got message from socket: #{message}"
        handle_message(message)
      end
    end

    def handle_message(data)
      data = JSON.parse(data) if data != ''
      info "decode json result: #{data}"
      publish 'incoming_api', data
    end
  end
end
