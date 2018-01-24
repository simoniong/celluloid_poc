require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra-websocket'
require 'celluloid'
require 'celluloid/current'

class StageWorker
  include Celluloid

  attr_accessor :delay_range
  def initialize(type=:fast)
    if type == :fast
      @delay_range = 5 
    else
      @delay_range = 2
    end  
  end

  def process(ws, data)
    sleep(rand(@delay_range)/10+0.5)
    ws.send(data)
  end
end

Celluloid::Actor[:slow_stage_pool] = StageWorker.pool(size: 100, args:[:slow])
Celluloid::Actor[:fast_stage_pool] = StageWorker.pool(size: 100, args:[:fase])

class App < Sinatra::Base
  # disable backend server level signal handling
  set :server_settings, { signals: false }
  # disable sinatra level signal handling
  set :traps, false

  set :status, 1
  set :restarting, EM::Channel.new
  get '/' do
    
    headers 'Access-Control-Allow-Origin' => '*'
    headers "Access-Control-Allow-Headers" => "*"
    
    if request.websocket?
      request.websocket do |ws|
        sid = nil
        ws.onopen do
          puts "client connected"
          sid = settings.restarting.subscribe { |msg| ws.send msg }
          status = 0
        end

        ws.onclose do
            warn("websocket closed")
            settings.restarting.unsubscribe(sid)
        end

        ws.onmessage do |msg|
              puts "receive: #{msg}"
              type = [:slow_stage_pool, :fast_stage_pool].sample

              pool = Celluloid::Actor[type]
              pool.process(ws,msg)
        end
      end
    else
      erb :index
    end
  end

  trap('TERM') do
    puts 'info: Got SIGTERM singal'
    puts 'notify subscriber to restarting'
    self.settings.restarting.push("restarting")
    puts 'done'
    quit!
  end
end

App.run! :port => 4448
