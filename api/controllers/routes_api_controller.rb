controller :routes do
  friendly_name "Routes API"
  description "This API allows you to create and view routes on server"
  authenticator :server
        
  action :create do
    title "Create a route"
    description "This action allows you to create routes"

    param :domain, "Domain name", :required => true, :type => String
    param :endpoint_name, "Endpoint address (ex@mp.le)", :required => true, :type => String
    param :endpoint_type, "Endpoint type: SMTPEndpoint | HTTPEndpoint | AddressEndpoint", :required => true, :type => String, :default => "HTTPEndpoint"
    param :spam_mode, "Route spam mode: Mark | Quarantine | Fail", :required => true, :type => String, :default => "Mark"
    param :mode, "Route mode: Endpoint | Accept | Hold | Bounce | Reject", :required => true, :type => String, :default => "Endpoint"
    param :name, "Route name (max 50)", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to create route", :attributes => {:errors => "A hash of error details"}
    error 'InvalidEndPoint', "The endpoint: {type} with name/address: {name} dose not exists", :attributes => {:type => "Endpoint type", :name => "Endpoint name"}
    error 'RouteNameMissing', "Route name is missing"
    error 'InvalidRouteName', "Route name is invalid"
    error 'RouteNameExists', "Route name already exists"

    returns Hash, :structure => :route

    action do
      route = identity.server.routes.find_by_name_and_domain(params.name, params.domain)
      if route.nil?
        route = Route.new
        route.domain = identity.server.domains.find_by_name(params.domain)
        route.server = identity.server
        route.name = params.name
        route.spam_mode = params.spam_mode
        route.endpoint_type = params.endpoint_type
        if params.endpoint_type == 'HTTPEndpoint'
          if identity.server.http_endpoints.find_by_name(params.endpoint_name).nil?
            error "InvalidEndPoint", :type => params.endpoint_type, :name => params.endpoint_name
          end
          route.endpoint_id = identity.server.http_endpoints.find_by_name(params.endpoint_name).id
        elsif params.endpoint_type == 'SMTPEndpoint'
          if identity.server.smtp_endpoints.find_by_name(params.endpoint_name).nil?
            error "InvalidEndPoint", :type => params.endpoint_type, :name => params.endpoint_name
          end
          route.endpoint_id = identity.server.smtp_endpoints.find_by_name(params.endpoint_name).id
        else
          if identity.server.address_endpoints.find_by_address(params.endpoint_name).nil?
            error "InvalidEndPoint", :type => params.endpoint_type, :name => params.endpoint_name
          end
          route.endpoint_id = identity.server.address_endpoints.find_by_address(params.endpoint_name).id
        end
        route.mode = params.mode
        route.created_at = Time.now
        route.updated_at = Time.now
        if route.save
          structure :route, route, :return => true
        else
          error_message = route.errors.full_messages.first
          if error_message == "Name is invalid"
            error "InvalidRouteName"
          else
            error "Unknown Error", error_message
          end
        end
      else
        error 'RouteNameExists'
      end

    end
  end
  
  action :query do
    title "Query route"
    description "This action allows you to query route"

    param :domain, "Domain name", :required => true, :type => String
    param :name, "Route name (max 50)", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query route", :attributes => {:errors => "A hash of error details"}
    error 'RouteIdMissing', "Route Id is missing"
    error 'RouteNotFound', "The route not found"

    returns Hash, :structure => :route

    action do
      route = identity.server.routes.find_by_name_and_domain(params.name, params.domain)
      if route.nil?
        error 'RouteNotFound'
      else
        structure :route, route, :return => true
      end
    end
  end

  action :update do
    title "Update route"
    description "This action allows you to update route"

    param :domain, "Domain name", :required => false, :type => String
    param :endpoint_name, "Endpoint address (ex@mp.le)", :required => false, :type => String
    param :endpoint_type, "Endpoint type: SMTPEndpoint | HTTPEndpoint | AddressEndpoint", :required => false, :type => String
    param :spam_mode, "Route spam mode: Mark | Quarantine | Fail", :required => false, :type => String
    param :mode, "Route mode: Endpoint | Accept | Hold | Bounce | Reject", :required => false, :type => String
    param :name, "Name of name@example.com", :required => false, :type => String
    param :id, "Id of route", :required => true, :type => Integer
    
    error 'ValidationError', "The provided data was not sufficient to query route", :attributes => {:errors => "A hash of error details"}
    error 'RouteIdMissing', "Route id is missing"
    error 'RouteNotFound', "The route not found"

    returns Hash, :structure => :route

    action do
      route = identity.server.routes.find_by_id(params.id)
      if route.nil?
        error 'RouteNotFound'
      else
        route.domain = params.domain if !params.domain.nil?
        route.name = params.name if !params.name.nil?
        route.spam_mode = params.spam_mode if !params.spam_mode.nil?
        route.endpoint_id = identity.server.address_endpoints.find_by_address(params.endpoint_name).id if !params.endpoint_name.nil?
        route.endpoint_type = params.endpoint_type if !params.endpoint_type.nil?
        route.mode = params.mode if !params.mode.nil?
        route.updated_at = Time.now
        if route.save
          structure :route, route, :return => true
        else
          error "Unknown Error", route.errors.full_messages.first
        end
      end
    end
  end

  action :delete do
    title "Delete a route"
    description "This action allows you to delete route"

    param :domain, "Domain name", :required => true, :type => String
    param :name, "Route name (max 50)", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query route", :attributes => {:errors => "A hash of error details"}
    error 'RouteIdMissing', "Route Id is missing"
    error 'RouteNotFound', "The route not found"
    error 'RouteNotDeleted', "Route could not be deleted"

    returns Hash

    action do
      route = identity.server.routes.find_by_name_and_domain(params.name, params.domain)
      if route.nil?
        error 'RouteNotFound'
      elsif route.delete
        {:message => "Route deleted successfully"}
      else
        error 'RouteNotDeleted'
      end
    end
  end
end


