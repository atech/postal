require './spec/rails_helper'
require './spec/api/controllers/domains_init'


describe "Domains API" do
  domain_valid = "cloudy.com"
  domain_invalid = "test domain"
  url_create = "/api/v1/domains/create"
  url_query = "/api/v1/domains/query"
  url_check = "/api/v1/domains/check"
  url_delete = "/api/v1/domains/delete"

  @credential = nil
  @domain_init = nil
  api_key = nil

  before(:all) do
    puts "about to prepare..."
    @domain_init = DomainsInit.new
    @domain_init.prepare
    @credential = @domain_init.get_credential
    api_key = @credential.key
  end

  after(:all) do
    puts "about to tear down..."
    @domain_init.tear_down
  end

  describe "Create Domain" do
    describe "Create domain request Without api token" do
      it "rejects to create domain" do
        post url_create, params: {name:"My Domain"}
        expect(response).to have_http_status(:success)
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
        #puts hash_body
        expect(hash_body[:status]).to match("error")
        expect(hash_body[:data][:code]).to match("AccessDenied")
      end
    end

    describe "Create domain request with Invalid domain name" do
      it("rejects invalid domain name"){
        params = {:name => "test domain"}
        post url_create, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
        #puts hash_body
        expect(response).to have_http_status(:success)
        expect(hash_body[:status]).to match("error")
        expect(hash_body[:data][:code]).to match("InvalidDomainName")
      }
    end

    describe "Create Domain with api key" do
      it "create a new domain" do
        params = {:name => domain_valid}
        post url_create, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
        #puts hash_body
        expect(response).to have_http_status(:success)
        expect(hash_body[:status]).to match("success")
        expect(hash_body[:data][:name]).to match(domain_valid)
      end
    end

  end

  describe "Actions on  existing domain" do
    before(:all) do
      params = {:name => domain_valid}
      post url_create, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
      #puts response.body
    end

    describe "Create a duplicate domain" do
      it "rejects to create another domain with the same name" do
        params = {:name => domain_valid}
        post url_create, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
        #puts hash_body
        expect(response).to have_http_status(:success)
        expect(hash_body[:status]).to match("error")
        expect(hash_body[:data][:code]).to match("DomainNameExists")
      end
    end

    describe "Query Domain" do

      describe "Query domain without api key" do
        it "Rejects without api key" do
          params = {:name => domain_valid}
          post url_query, params: params, as: :json
          hash_body = nil
          expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
          #puts hash_body
          expect(response).to have_http_status(:success)
          expect(hash_body[:status]).to match("error")
          expect(hash_body[:data][:code]).to match("AccessDenied")
        end
      end

      describe "Query for non-existent domain" do
        it "Returns NotFound response" do
          params = {:name => domain_invalid}
          post url_query, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
          hash_body = nil
          expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
          #puts hash_body
          expect(response).to have_http_status(:success)
          expect(hash_body[:status]).to match("error")
          expect(hash_body[:data][:code]).to match("NotFound")
        end
      end

      describe "Query with api key" do

        it "Returns domain" do
          params = {:name => domain_valid}
          post url_query, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
          hash_body = nil
          expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
          #puts hash_body
          expect(response).to have_http_status(:success)
          expect(hash_body[:status]).to match("success")
          expect(hash_body[:data][:name]).to match(domain_valid)
        end
      end
    end

    describe "Check Domain status" do
      it "returns domain" do
        params = {:name => domain_valid}
        post url_check, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
        #puts hash_body
        expect(response).to have_http_status(:success)
        expect(hash_body[:status]).to match("success")
        expect(hash_body[:data][:name]).to match(domain_valid)
      end
    end

    describe "Delete Domain" do

      it "deletes domain" do
        params = {:name => domain_valid}
        post url_delete, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
        #puts response.body

        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
        expect(response).to have_http_status(:success)
        expect(hash_body[:status]).to match("success")
        expect(hash_body[:data][:message]).to match("Domain deleted successfully")
      end

      it "returns NotFound response" do
        params = {:name => domain_invalid}
        post url_delete, params: params, headers: {"X-Server-API-Key":api_key}, as: :json
        #puts response.body

        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
        expect(response).to have_http_status(:success)
        expect(hash_body[:status]).to match("error")
        expect(hash_body[:data][:code]).to match("DomainNotFound")
      end
    end
  end
end

