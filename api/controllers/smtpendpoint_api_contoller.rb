controller :smtpendpoints do
  friendly_name "SmtpEndpoint API"
  description "This API allows you to create and view smtp endpoints on server"
  authenticator :server
        
  action :create do
    title "Create smtp endpoint"
    description "This action allows you to create smtp endpoints"
  
    param :name, "Endpoint name", :required => true, :type => String
    param :hostname, "Endpoint hostname", :required => true, :type => String
    param :ssl_mode, "Endpoint ssl mode: None | Auto | STARTTLS | TLS", :required => true, :type => String
    param :port, "Endpoint port default: 25", :required => false, :type => Integer, :default => 25

    error 'ValidationError', "The provided data was not sufficient to create smtp endpoint", :attributes => {:errors => "A hash of error details"}
    error 'SmtpEndPointNameMissing', "SmtpEndPoint name is missing"
    error 'InvalidsmtpEndPointName', "SmtpEndPoint name is invalid"
    error 'SmtpEndPointNameExists', "SmtpEndPoint name already exists"

    returns Hash, :structure => :smtpendpoint

    action do
      smtpendpoint = identity.server.smtp_endpoints.find_by_name_and_hostname(params.name, params.hostname)
      if smtpendpoint.nil?
        smtpendpoint = SMTPEndpoint.new
        smtpendpoint.server = identity.server
        smtpendpoint.name = params.name
        smtpendpoint.hostname = params.hostname
        smtpendpoint.ssl_mode = params.ssl_mode
        smtpendpoint.port = params.port
        smtpendpoint.created_at = Time.now
        smtpendpoint.updated_at = Time.now
        if smtpendpoint.save
          structure :smtpendpoint, smtpendpoint, :return => true
        else
          error_message = smtpendpoint.errors.full_messages.first
          if error_message == "Name is invalid"
            error "InvalidSmtpEndPointName"
          else
            error "Unknown Error", error_message
          end
        end
      else
        error 'SmtpEndPointNameExists'
      end
    end
  end

  action :query do
    title "Query smtp endpoint"
    description "This action allows you to query smtp endpoint"

    param :name, "Endpoint name", :required => true, :type => String
    param :hostname, "Endpoint hostname", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query smtp endpoint", :attributes => {:errors => "A hash of error details"}
    error 'SmtpEndpointIdMissing', "SmtpEndpoint id is missing"
    error 'SmtpEndpointNotFound', "The smtp endpoint not found"

    returns Hash, :structure => :smtpendpoint

    action do
      smtpendpoint = identity.server.smtp_endpoints.find_by_name_and_hostname(params.name, params.hostname)
      if smtpendpoint.nil?
        error 'SmtpEndpointNotFound'
      else
        structure :smtpendpoint, smtpendpoint, :return => true
      end
    end
  end

  action :update do
    title "Update smtp endpoint"
    description "This action allows you to update smtp endpoint"

    param :name, "Endpoint name", :required => false, :type => String
    param :hostname, "Endpoint hostname", :required => false, :type => String
    param :ssl_mode, "Endpoint ssl mode: None | Auto | STARTTLS | TLS", :required => false, :type => String
    param :port, "Endpoint port default: 25", :required => false, :type => Integer, :default => 25
    param :id, "Id of smtp endpoint", :required => true, :type => Integer

    error 'ValidationError', "The provided data was not sufficient to query smtp endpoint", :attributes => {:errors => "A hash of error details"}
    error 'SmtpEndpointIdMissing', "SmtpEndpoint id is missing"
    error 'SmtpEndpointNotFound', "The smtp endpoint not found"

    action do
      smtpendpoint = identity.server.smtp_endpoints.find_by_id(params.id)
      if smtpendpoint.nil?
        error "SmtpEndpointNotFound"
      else
        smtpendpoint.name = params.name if !params.name.nil?
        smtpendpoint.port = params.port if !params.port.nil?
        smtpendpoint.hostname = params.hostname if !params.hostname.nil? 
        smtpendpoint.ssl_mode = params.ssl_mode if !params.ssl_mode.nil?
        smtpendpoint.updated_at = Time.now
        if smtpendpoint.save
          structure :smtpendpoint, smtpendpoint, :return => true
        else
          error "Unknown Error", smtpendpoint.errors.full_messages.first
        end
      end
    end
  end

  action :delete do
    title "Delete a smtp endpoint"
    description "This action allows you to delete smtp endpoint"

    param :name, "Endpoint name", :required => true, :type => String
    param :hostname, "Endpoint hostname", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query smtp endpoint", :attributes => {:errors => "A hash of error details"}
    error 'SmtpEndpointIdMissing', "SmtpEndpoint id is missing"
    error 'SmtpEndpointNotFound', "The smtp endpoint not found"
    error 'SmtpEndpointNotDeleted', "SmtpEndpoint could not be deleted"


    returns Hash, :structure => :smtpendpoint
    
    action do
      smtpendpoint = identity.server.smtp_endpoints.find_by_name_and_hostname(params.name, params.hostname)
      if smtpendpoint.nil?
        error 'SmtpEndpointNotFound'
      elsif smtpendpoint.delete
        {:message => "SmtpEndpoint deleted successfully"}
      else
        error 'SmtpEndpointNotDeleted'
      end
    end
  end
end