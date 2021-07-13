structure :domain do
  basic :id, :type => Integer
  basic :uuid, :type => String
  basic :name, :type => String
  basic :server_id, :type => Integer

  group :verification do
    basic :verification_token, :type => String
    basic :verification_method, :type => String
  end

  basic :created_at, :type => String
  basic :updated_at, :type => String
  basic :dns_checked_at, :type => String
  basic :owner_id, :type => Integer
  basic :owner_type, :type => String

  group :spf do
    basic :spf_record, :type => String
    basic :spf_status, :type => String
    basic :spf_error, :type => String
  end

  group :dkim do
    basic :dkim_record_name, :type => String
    basic :dkim_record, :type => String
    basic :dkim_status, :type => String
    basic :dkim_error, :type => String
  end

  group :mx_record do
    basic :mx_status, :type => String
    basic :mx_error, :type => String
  end

  group :return_path do
    basic :return_path_domain, :type => String
    basic :return_path_status, :type => String
    basic :return_path_error, :type => String
  end
end
