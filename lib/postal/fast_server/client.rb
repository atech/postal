require 'stringio'

module Postal
  module FastServer
    class Client
      class ClientWentAway < StandardError; end
      class BadRequest < StandardError; end

      attr_reader :remote_ip

      def initialize(socket, options)
        @raw_socket = socket
        @options = options
      end

      def run
        Timeout.timeout(15) do
          if Postal.config.fast_server.proxy_protocol

            # gets without readahead
            line = ""
            char = nil
            while(char != "\n")
              char = @raw_socket.read(1)
              line << char
            end
            line.chomp!

            if m = line.match(/\APROXY (.+) (.+) (.+) (.+) (.+)\z/)
              @remote_ip = m[2]
            else
              return false
            end
          end

          if self.ssl?
            @socket = OpenSSL::SSL::SSLSocket.new(@raw_socket, self.class.ssl_context)
            @socket.accept
          else
            @socket = @raw_socket
          end

          Timeout::timeout(20) do
            # Read the request line
            request = @socket.gets.to_s.chomp
            # Split the request into its 3 parts
            method, path, protocol = request.split(' ', 3)

            raise BadRequest unless method && path && protocol

            # Create an empty header set
            header_set = HTTPHeaderSet.new
            # Read each header and populate the header set
            loop do
              header = @socket.gets
              if header.nil?
                raise ClientWentAway
              elsif header.chomp == ""
                break
              else
                header_set << HTTPHeader.from_string(header.chomp)
              end
            end

            extract_ip(header_set)

            # At this point, one might want to read the request body, but I don't think we need it.

            # Build rack request
            server_name, server_port = header_set['Host'].try(:value).to_s.split(":", 2)
            request = {
              "REQUEST_METHOD" => method,
              "SCRIPT_NAME" => "",
              "PATH_INFO" => path.split('?', 2)[0],
              "QUERY_STRING" => path.split('?', 2)[1],
              "SERVER_NAME" => server_name || "",
              "SERVER_PORT" => server_name || "",
              "rack.version" => [1, 3],
              "rack.url_scheme" => ssl? ? "https" : "http",
              "rack.input" => StringIO.new(""),
              "rack.errors" => STDERR,
              "rack.multithread" => true,
              "rack.multiprocess" => true,
              "rack.run_once" => false,
              "rack.hijack" => false,
              "rack.hijack_io" => false,
              "REMOTE_ADDR" => remote_ip,
            }

            # Add request headers to rack hash
            header_set.headers.each do |header|
              request["HTTP_" + header.key.gsub('-', '_').upcase] = header.value
            end

            # Call the rack app and process the result
            code, headers, body = Interface.new.call(request)
            response = "HTTP/1.1 #{code} #{Rack::Utils::HTTP_STATUS_CODES[code]}\r\n"
            headers.each do |k,v|
              response << "#{k}:#{v}\r\n"
            end
            response << "\r\n"
            body.each do |data|
              response << data
            end
            @socket.write(response)
          end
        end
      rescue ClientWentAway, Timeout::Error, Errno::ECONNRESET
        # We don't really care if a client has disapeared, close the sockets and carry on.
      rescue OpenSSL::SSL::SSLError
        # Don't worry about SSL negotiation failures, disconnect and carry on
      rescue BadRequest
        # We couldn't read a proper HTTP request, disconnect the client
      rescue => e
        if defined?(Raven)
          Raven.capture_exception(e)
        end
      ensure
        @socket.close rescue nil
        @raw_socket.close rescue nil
      end

      def ssl?
        !!@options[:ssl]
      end

      def extract_ip(header_set)
        return if @remote_ip

        if header_set['X-Forwarded-For']
          ips = header_set['X-Forwarded-For'].value.split(', ')

          if ips[0]
            @remote_ip = ips[0]
            return
          end
        end

        @remote_ip = @raw_socket.peeraddr[3].sub('::ffff:', '')
      end

      def self.ssl_context(domain_name = nil)
        @ssl_certificates ||= {}
        unless @ssl_certificates_refreshed && @ssl_certificates_refreshed > Time.now.utc.beginning_of_day
          @ssl_certificates_refreshed = Time.now.utc
          @ssl_certificates = {}
        end
        @ssl_certificates[domain_name] ||= OpenSSL::SSL::SSLContext.new.tap do |ssl_context|
          if domain_name
            if domain = TrackCertificate.active.where(:domain => domain_name).first
              ssl_context.cert = domain.certificate_object
              ssl_context.extra_chain_cert = domain.intermediaries_array
              ssl_context.key  = domain.key_object
            end
          end

          if ssl_context.cert.nil?
            ssl_context.cert = Postal.fast_server_default_certificates[0]
            ssl_context.extra_chain_cert = Postal.fast_server_default_certificates[1..-1]
            ssl_context.key  = Postal.fast_server_default_private_key
          end

          ssl_context.ssl_version = "SSLv23"
          ssl_context.ciphers = 'EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !RC4 !DH'
          ssl_context.options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |
                                OpenSSL::SSL::OP_NO_SSLv2 |
                                OpenSSL::SSL::OP_NO_SSLv3 |
                                OpenSSL::SSL::OP_NO_COMPRESSION |
                                OpenSSL::SSL::OP_CIPHER_SERVER_PREFERENCE

          if ssl_context.respond_to?('tmp_ecdh_callback=')
            ssl_context.tmp_ecdh_callback = Proc.new do |*a|
              OpenSSL::PKey::EC.new("prime256v1")
            end
          end

          unless domain_name
            ssl_context.servername_cb = Proc.new do |ctx, hostname|
              self.ssl_context(hostname)
            end
          end
        end
      end

    end
  end
end
