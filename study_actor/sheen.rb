require 'celluloid'

class Sheen
  include Celluloid

  def initialize(name)
    @name = name
  end

  def set_status(status)
    sleep 10
    @status = status
  end

  def report
    "#{@name} is #{@status}"
  end
end
