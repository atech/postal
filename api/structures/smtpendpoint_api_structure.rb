structure :smtpendpoint do
    basic :id, :type => Integer
    basic :uuid, :type => String
    basic :server_id, :type => Integer
    basic :name, :type => String
    basic :hostname, :type => String
    basic :ssl_mode, :type => String
    basic :error, :type => String
    basic :disabled_until, :type => String
    basic :last_used_at, :type => String
    basic :created_at, :type => String
    basic :updated_at, :type => String
end