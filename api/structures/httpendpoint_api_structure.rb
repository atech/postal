structure :httpendpoint do
    basic :id, :type => Integer
    basic :uuid, :type => String
    basic :server_id, :type => Integer
    basic :name, :type => String
    basic :url, :type => String
    basic :encoding, :type => String
    basic :format, :type => String
    basic :strip_replies, :type => String
    basic :include_attachments, :type => String
    basic :last_used_at, :type => String
    basic :error, :type => String
    basic :disabled_until, :type => String
    basic :created_at, :type => String
    basic :updated_at, :type => String
    basic :timeout, :type => Integer
end