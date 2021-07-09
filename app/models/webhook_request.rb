# == Schema Information
#
# Table name: webhook_requests
#
#  id          :integer          not null, primary key
#  server_id   :integer
#  webhook_id  :integer
#  url         :string(255)
#  event       :string(255)
#  uuid        :string(255)
#  payload     :text(65535)
#  attempts    :integer          default(0)
#  retry_after :datetime
#  error       :text(65535)
#  created_at  :datetime
#

class WebhookRequest < ApplicationRecord

  include HasUUID

  RETRIES = {1 => 2.minutes, 2 => 3.minutes, 3 => 6.minutes, 4 => 10.minutes, 5 => 15.minutes}

  belongs_to :server
  belongs_to :webhook, :optional => true

  validates :url, :presence => true
  validates :event, :presence => true

  serialize :payload, Hash

  after_commit :queue, :on => :create

  def self.trigger(server, event, payload = {})
    unless server.is_a?(Server)
      server = Server.find(server.to_i)
    end

    webhooks = server.webhooks.enabled.includes(:webhook_events).references(:webhook_events).where("webhooks.all_events = ? OR webhook_events.event = ?", true, event)
    webhooks.each do |webhook|
      server.webhook_requests.create!(:event => event, :payload => payload, :webhook => webhook, :url => webhook.url)
    end
  end

  def self.requeue_all
    where("retry_after < ?", Time.now).each(&:queue)
  end

  def queue
    WebhookDeliveryJob.queue(:main, :id => self.id)
  end

  def deliver
    logger = Postal.logger_for(:webhooks)
    payload = {:event => self.event, :timestamp => self.created_at.to_f, :payload => self.payload, :uuid => self.uuid}.to_json
    logger.info "[#{id}] Sending webhook request to `#{self.url}`"
    result = Postal::HTTP.post(self.url, :sign => true, :json => payload, :timeout => Postal.config.general.webhook_timeout)
    self.attempts += 1
    self.retry_after = RETRIES[self.attempts]&.from_now
    self.server.message_db.webhooks.record(
      :event => self.event,
      :url => self.url,
      :webhook_id => self.webhook_id,
      :attempt => self.attempts,
      :timestamp => Time.now.to_f,
      :payload => self.payload.to_json,
      :uuid => self.uuid,
      :status_code => result[:code],
      :body => result[:body],
      :will_retry => (self.retry_after ? 0 : 1)
    )

    if result[:code] >= 200 && result[:code] < 300
      logger.info "[#{id}]   -> Received #{result[:code]} status code. That's OK."
      self.destroy
      self.webhook&.update_column(:last_used_at, Time.now)
      true
    else
      logger.error "[#{id}]   -> Received #{result[:code]} status code. That's not OK."
      self.error = "Couldn't send to URL. Code received was #{result[:code]}"
      if self.retry_after
        logger.info "[#{id}]   -> Will retry #{self.retry_after} (this was attempt #{self.attempts})"
        self.save
      else
        logger.info "[#{id}]   -> Have tried #{self.attempts} times. Giving up."
        self.destroy
      end
      false
    end
  end

end
