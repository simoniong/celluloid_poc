class GameBackend
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  def initialize
    subscribe('incoming_api', :handle_incoming_api)
  end

  def handle_incoming_api(topic, data)
    publish 'notify_response', data
  end
end
