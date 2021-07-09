structure :route do
    basic :id, :type => Integer
    basic :uuid, :type => String
    basic :server_id, :type => Integer
    basic :domain_id, :type => Integer
    basic :endpoint_id, :type => Integer
    # basic :endpoint_name, :type => String
    basic :name, :type => String
    basic :spam_mode, :type => String
    basic :created_at, :type => String
    basic :updated_at, :type => String
    basic :token, :type => String
    basic :mode, :type => String
end