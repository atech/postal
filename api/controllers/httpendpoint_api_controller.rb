controller :httpendpoints do
  friendly_name "HttpEndpoint API"
  description "This API allows you to create and view http endpoints on server"
  authenticator :server
        
  action :create do
    title "Create http endpoint"
    description "This action allows you to create http endpoints"

    param :name, "Endpoint name", :required => true, :type => String
    param :url, "Endpoint url", :required => true, :type => String
    param :encoding, "Endpoint encoding: BodyAsJSON | FormData", :required => true, :type => String, :default => "BodyAsJSON"
    param :format, "Endpoint format: Hash | RawMessage", :required => true, :type => String, :default => "RawMessage"
    param :strip_replies, "Endpoint strip replies", :required => true, :type => String, :default => "yes"
    param :include_attachments, "Endpoint include attachments", :required => true, :type => String, :default => "yes"
    param :timeout, "Endpoint timeout default: 5s", :required => false, :type => Integer, :default => 5

    error 'ValidationError', "The provided data was not sufficient to create http endpoint", :attributes => {:errors => "A hash of error details"}
    error 'HttpEndPointNameMissing', "HttpEndPoint name is missing"
    error 'InvalidHttpEndPointName', "HttpEndPoint name is invalid"
    error 'HttpEndPointNameExists', "HttpEndPoint name already exists"

    returns Hash, :structure => :httpendpoint

    action do
      httpendpoint = identity.server.http_endpoints.find_by_name(params.name)
      if httpendpoint.nil?
        httpendpoint = HTTPEndpoint.new
        httpendpoint.server = identity.server
        httpendpoint.name = params.name
        httpendpoint.url = params.url
        httpendpoint.encoding = params.encoding
        httpendpoint.format = params.format
        httpendpoint.strip_replies = params.strip_replies == 'yes' ? true : false
        httpendpoint.include_attachments = params.include_attachments =='yes' ? true : false
        httpendpoint.timeout = params.timeout
        httpendpoint.created_at = Time.now
        httpendpoint.updated_at = Time.now
        if httpendpoint.save
          structure :httpendpoint, httpendpoint, :return => true
        else
          error_message = httpendpoint.errors.full_messages.first
          if error_message == "Name is invalid"
            error "InvalidHttpEndPointName"
          else
            error "Unknown Error", error_message
          end
        end
      else
        error 'HttpEndPointNameExists'
      end
    end
  end

  action :query do
    title "Query http endpoint"
    description "This action allows you to query http endpoint"

    param :name, "Endpoint name", :required => true, :type => String
    param :url, "Endpoint url", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query http endpoint", :attributes => {:errors => "A hash of error details"}
    error 'HttpEndpointIdMissing', "HttpEndpoint id is missing"
    error 'HttpEndpointNotFound', "The http endpoint not found"

    returns Hash, :structure => :httpendpoint

    action do
      httpendpoint = identity.server.http_endpoints.find_by_name_and_url(params.name, params.url)
      if httpendpoint.nil?
        error 'HttpEndpointNotFound'
      else
        structure :httpendpoint, httpendpoint, :return => true
      end
    end
  end

  action :update do
    title "Update http endpoint"
    description "This action allows you to update http endpoint"

    param :name, "Endpoint name", :required => false, :type => String
    param :url, "Endpoint url", :required => false, :type => String
    param :encoding, "Endpoint encoding: BodyAsJSON | FormData", :required => false, :type => String
    param :format, "Endpoint format: Hash | RawMessage", :required => false, :type => String
    param :strip_replies, "Endpoint strip replies", :required => false, :type => String
    param :include_attachments, "Endpoint include attachments", :required => false, :type => String
    param :timeout, "Endpoint timeout default: 5s", :required => false, :type => Integer, :default => 5
    param :id, "Id of http endpoint", :required => true, :type => Integer

    error 'ValidationError', "The provided data was not sufficient to query http endpoint", :attributes => {:errors => "A hash of error details"}
    error 'HttpEndpointIdMissing', "HttpEndpoint id is missing"
    error 'HttpEndpointNotFound', "The http endpoint not found"

    action do
      httpendpoint = identity.server.http_endpoints.find_by_id(params.id)
      if httpendpoint.nil?
        error "HttpEndpointNotFound"
      else
        httpendpoint.name = params.name if !params.name.nil?
        httpendpoint.url = params.url if !params.url.nil? 
        httpendpoint.encoding = params.encoding if !params.encoding.nil?
        httpendpoint.format = params.format if !params.format.nil?
        httpendpoint.strip_replies = (params.strip_replies == 'yes' ? true : false) if !params.strip_replies.nil?
        httpendpoint.include_attachments = (params.include_attachments =='yes' ? true : false) if !params.include_attachments.nil?
        httpendpoint.timeout = params.timeout if !params.timeout.nil?
        httpendpoint.updated_at = Time.now
        if httpendpoint.save
          structure :httpendpoint, httpendpoint, :return => true
        else
          error "Unknown Error", httpendpoint.errors.full_messages.first
        end
      end
    end
  end

  action :delete do
    title "Delete a http endpoint"
    description "This action allows you to delete http endpoint"

    param :name, "Endpoint name", :required => true, :type => String
    param :url, "Endpoint url", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query http endpoint", :attributes => {:errors => "A hash of error details"}
    error 'HttpEndpointIdMissing', "HttpEndpoint id is missing"
    error 'HttpEndpointNotFound', "The http endpoint not found"
    error 'HttpEndpointNotDeleted', "HttpEndpoint could not be deleted"


    returns Hash, :structure => :httpendpoint
    
    action do
      httpendpoint = identity.server.http_endpoints.find_by_name_and_url(params.name, params.url)
      if httpendpoint.nil?
        error 'HttpEndpointNotFound'
      elsif httpendpoint.delete
        {:message => "HttpEndpoint deleted successfully"}
      else
        error 'HttpEndpointNotDeleted'
      end
    end
  end
end
