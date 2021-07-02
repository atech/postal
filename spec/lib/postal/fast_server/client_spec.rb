# frozen_string_literal: true

require 'rails_helper'

describe Postal::FastServer::Client do
  class TestSocket
    attr_reader :response, :peeraddr

    def initialize(lines, peeraddr)
      @lines = lines
      @peeraddr = peeraddr
      @line_pointer = 0
    end

    def gets
      line = @lines[@line_pointer]
      @line_pointer += 1
      line
    end

    def write(response)
      @response = response
    end
  end

  describe '#remote_ip' do
    it 'returns the IPv4 peer address' do
      socket = TestSocket.new(
        [
          'GET / HTTP/1.1',
          'Host: postal.mydomain.com',
          ''
        ],
        ['AF_INET', 80, '221.186.184.68', '221.186.184.68']
      )

      client = Postal::FastServer::Client.new(socket, ssl: false)
      client.run
      expect(client.remote_ip).to eq '221.186.184.68'
    end

    it 'returns the IPv4 peer address mapped as IPv6' do
      socket = TestSocket.new(
        [
          'GET / HTTP/1.1',
          'Host: postal.mydomain.com',
          ''
        ],
        ['AF_INET', 80, '::ffff:221.186.184.68', '::ffff:221.186.184.68']
      )

      client = Postal::FastServer::Client.new(socket, ssl: false)
      client.run
      expect(client.remote_ip).to eq '221.186.184.68'
    end

    it 'returns the peer in the X-Forwarded-For header (single value)' do
      socket = TestSocket.new(
        [
          'GET / HTTP/1.1',
          'Host: postal.mydomain.com',
          'X-Forwarded-For: 221.186.184.68',
          ''
        ],
        ['AF_INET', 80, '172.17.0.5', '172.17.0.5']
      )

      client = Postal::FastServer::Client.new(socket, ssl: false)
      client.run
      expect(client.remote_ip).to eq '221.186.184.68'
    end

    it 'returns the peer in the X-Forwarded-For header (multiple values)' do
      socket = TestSocket.new(
        [
          'GET / HTTP/1.1',
          'Host: postal.mydomain.com',
          'X-Forwarded-For: 221.186.184.68, 172.17.0.0',
          ''
        ],
        ['AF_INET', 80, '172.17.0.5', '172.17.0.5']
      )

      client = Postal::FastServer::Client.new(socket, ssl: false)
      client.run
      expect(client.remote_ip).to eq '221.186.184.68'
    end
  end

  describe 'response' do
    describe 'request for /' do
      it 'returns a empty response' do
        socket = TestSocket.new(
          [
            'GET / HTTP/1.1',
            'Host: postal.mydomain.com',
            ''
          ],
          ['AF_INET', 80, '221.186.184.68', '221.186.184.68']
        )
        client = Postal::FastServer::Client.new(socket, ssl: false)
        client.run

        expect(socket.response).to eq [
          'HTTP/1.1 200 OK',
          '',
          'Hello.'
        ].join("\r\n")
      end
    end
  end
end