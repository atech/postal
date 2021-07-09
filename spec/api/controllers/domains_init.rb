class DomainsInit < ApplicationController

  def initialize
    puts "Initializing DomainsInit"
    @user_email = "john.doe@example.com"
    @org_name = "Mailer Organization"
    @org_permalink = "mailer-orgs"
    @server_name = "Mailer Server"
    @server_permalink = "mailer-server"
    @cred_name = "Mailer Credentials"

    @user = User.find_by_email_address(@user_email)
    @organization = Organization.find_by_permalink(@org_permalink)
    @server = Server.find_by_permalink(@server_permalink)
    @credential = Credential.find_by_name(@cred_name)
  end

  def prepare
    if @user.nil?
      @user = create_user
    end

    if @organization.nil?
      @organization = create_organization
    end

    if @server.nil?
      @server = create_server
    end

    if @credential.nil?
      @credential = create_credential
    end
  end

  def create_user
    user = User.new
    user.email_address = @user_email
    user.first_name = "John"
    user.last_name = "Doe"
    user.password = "john.doe_123"
    user.email_verified_at = Time.now
    if user.save
      puts "User created"
      user
    else
      puts "User could not be created"
      put_errors user.errors.full_messages
    end
  end

  def create_organization
    organization = Organization.new
    organization.name = @org_name
    organization.permalink = @org_permalink
    organization.owner = @user
    if organization.save
      puts "Organization created"
      organization
    else
      puts "Could not create Organization"
      put_errors organization.errors.full_messages
    end
  end

  def create_server
    server = Server.new
    server.organization = @organization
    server.name = @server_name
    server.permalink = @server_permalink
    server.mode = "Development"
    if server.save
      puts "Server created"
      server
    else
      puts "Server could not be created"
      put_errors server.errors.full_messages
    end
  end

  def create_credential
    cred = Credential.new
    cred.name = @cred_name
    cred.server = @server
    cred.type = "API"
    if cred.save
      puts "Credential created"
      cred
    else
      puts "Could not create credential"
      put_errors cred.errors.full_messages
    end
  end

  def get_credential
    @credential
  end

  def tear_down
    unless @credential.delete
      put_errors @credential.errors.full_messages
    end
    unless @server.delete
      put_errors @server.errors.full_messages
    end
    unless @organization.delete
      put_errors @organization.errors.full_messages
    end
    unless @user.delete
      put_errors @user.errors.full_messages
    end
  end

  def get_organization
    @organization
  end

  private
  def put_errors(errors)
    for error in errors
      puts " * #{error}"
    end
  end
end
