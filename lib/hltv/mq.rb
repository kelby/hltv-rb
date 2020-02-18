module Hltv
  class Mq
    def publish(message)
      @conn ||= Bunny.new
      @conn.start

      @ch ||= @conn.create_channel
      @q  = @ch.queue("bunny.examples.hello_world", :auto_delete => true)
      @x  = @ch.default_exchange

      @x.publish(message, :routing_key => @q.name)
    end
  end
end
