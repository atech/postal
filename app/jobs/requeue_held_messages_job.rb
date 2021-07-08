class RequeueHeldMessagesJob < Postal::Job
  def perform
    Server.all.each do |server|
      if server.mode != "Development" && !server.queued_messages.first
        retry_limit = server.send_limit.nil? ? 200 : server.send_limit - server.throughput_stats[:outgoing]
        db = server.message_db
        query = { where: { held: 1 }, limit: retry_limit }
        messages = db.messages(query)
        messages.each { |m| m.add_to_message_queue(manual: true) }
      end
    end
  end
end
