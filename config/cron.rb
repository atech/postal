module Clockwork

  configure do |config|
    config[:tz] = 'UTC'
    config[:logger] = Postal.logger_for(:cron)
  end

  every 1.minute, 'every-1-minutes' do
    RequeueWebhooksJob.queue(:main)
    SendNotificationsJob.queue(:main)
  end

  every 15.minutes, 'every-15-minutes', :at => ['**:00', '**:15', '**:30', '**:45'] do
    RenewTrackCertificatesJob.queue(:main)
  end

  every 1.hour, 'every-hour', :at => ['**:15'] do
    CheckAllDNSJob.queue(:main)
    RequeueHeldMessagesJob.queue(:main)
    ExpireHeldMessagesJob.queue(:main)
    CleanupAuthieSessionsJob.queue(:main)
  end

  every 1.hour, 'every-hour', :at => ['**:45'] do
    PruneWebhookRequestsJob.queue(:main)
  end

  every 1.day, 'every-day', :at => ['03:00'] do
    ProcessMessageRetentionJob.queue(:main)
    PruneSuppressionListsJob.queue(:main)
  end

end
