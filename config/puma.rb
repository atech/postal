require_relative '../lib/postal/config'
threads_count = Postal.config.web_server&.max_threads&.to_i || 5
threads         threads_count, threads_count
bind_address  = Postal.config.web_server&.bind_address || '127.0.0.1'
bind_port     = Postal.config.web_server&.port&.to_i || 5000
environment     Postal.config.rails&.environment || 'development'

ssl_enabled = Postal.config.web_server&.ssl_enabled || false
server_key =  Postal.config.web_server&.server_key  || 'config/fast_server.key'
server_crt =  Postal.config.web_server&.server_crt || 'config/fast_server.cert'
ssl_ciphers = Postal.config.web_server&.tls_ciphers || 'TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA'

prune_bundler
quiet false

if ssl_enabled
  bind  "ssl://#{bind_address}:#{bind_port}?key=#{server_key}&cert=#{server_crt}&ssl_cipher_list=#{ssl_ciphers}"
else
  bind  "tcp://#{bind_address}:#{bind_port}"
end

unless ENV['LOG_TO_STDOUT']
  stdout_redirect Postal.log_root.join('puma.log'), Postal.log_root.join('puma.log'), true
end

if ENV['APP_ROOT']
  directory ENV['APP_ROOT']
end
