controller :addressendpoints do
  friendly_name "AddressEndpoint API"
  description "This API allows you to create and view address endpoints on server"
  authenticator :server

  action :create do
    title "Create address endpoint"
    description "This action allows you to create address endpoints"

    param :address, "Endpoint address", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to create address endpoint", :attributes => {:errors => "A hash of error details"}
    error 'AddressEndPointNameMissing', "AddressEndPoint name is missing"
    error 'InvalidAddressEndPointName', "AddressEndPoint name is invalid"
    error 'AddressEndPointNameExists', "AddressEndPoint name already exists"

    returns Hash, :structure => :addressendpoint

    action do
      addressendpoint = identity.server.address_endpoints.find_by_address(params.address)
      if addressendpoint.nil?
        addressendpoint = AddressEndpoint.new
        addressendpoint.server = identity.server
        addressendpoint.address = params.address
        addressendpoint.created_at = Time.now
        addressendpoint.updated_at = Time.now
        if addressendpoint.save
          structure :addressendpoint, addressendpoint, :return => true
        else
          error_message = addressendpoint.errors.full_messages.first
          if error_message == "Name is invalid"
            error "InvalidAddressEndPointName"
          else
            error "Unknown Error", error_message
          end
        end
      else
        error 'AddressEndPointNameExists'
      end
    end
  end

  action :query do
    title "Query address endpoint"
    description "This action allows you to query address endpoint"

    param :address, "Endpoint address", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query address endpoint", :attributes => {:errors => "A hash of error details"}
    error 'AddressEndpointIdMissing', "AddressEndpoint id is missing"
    error 'AddressEndpointNotFound', "The address endpoint not found"

    returns Hash, :structure => :addressendpoint

    action do
      addressendpoint = identity.server.address_endpoints.find_by_address(params.address)
      if addressendpoint.nil?
        error 'AddressEndpointNotFound'
      else
        structure :addressendpoint, addressendpoint, :return => true
      end
    end
  end

  action :update do
    title "Update address endpoint"
    description "This action allows you to update address endpoint"

    param :address, "Endpoint address", :required => true, :type => String
    param :id, "Id of address endpoint", :required => true, :type => Integer

    error 'ValidationError', "The provided data was not sufficient to query address endpoint", :attributes => {:errors => "A hash of error details"}
    error 'AddressEndpointIdMissing', "AddressEndpoint id is missing"
    error 'AddressEndpointNotFound', "The address endpoint not found"

    action do
      addressendpoint = identity.server.address_endpoints.find_by_id(params.id)
      if addressendpoint.nil?
        error "AddressEndpointNotFound"
      else
        addressendpoint.address = params.address if !params.address.nil?
        addressendpoint.updated_at = Time.now
        if addressendpoint.save
          structure :addressendpoint, addressendpoint, :return => true
        else
          error "Unknown Error", addressendpoint.errors.full_messages.first
        end
      end
    end
  end

  action :delete do
    title "Delete a address endpoint"
    description "This action allows you to delete address endpoint"

    param :address, "Endpoint address", :required => true, :type => String

    error 'ValidationError', "The provided data was not sufficient to query address endpoint", :attributes => {:errors => "A hash of error details"}
    error 'AddressEndpointIdMissing', "AddressEndpoint id is missing"
    error 'AddressEndpointNotFound', "The address endpoint not found"
    error 'AddressEndpointNotDeleted', "AddressEndpoint could not be deleted"


    returns Hash, :structure => :addressendpoint
    
    action do
      addressendpoint = identity.server.address_endpoints.find_by_address(params.address)
      if addressendpoint.nil?
        error 'AddressEndpointNotFound'
      elsif addressendpoint.delete
        {:message => "AddressEndpoint deleted successfully"}
      else
        error 'AddressEndpointNotDeleted'
      end
    end
  end
end