require 'rails_helper'

describe Postal::SMTPServer::Server do
  let(:credential) do
    s = Server.first
    c = create(:credential, server: s)
    create :domain, owner: c.server, name: 'example.com'
    c
  end

  let(:sender) { TCPSocket.open 'localhost', 2525 }

  before :all do
    Thread.new do
      Postal::SMTPServer::Server.new(debug: true).run
    end
  end

  it 'should receive message' do
    client = sender
    send_mail client, credential
    answers = []
    8.times do
      line = client.gets
      answers << line.chomp
    end
    expect_answers answers
  end

  it 'should receive mutiple messages' do
    begin_time = Time.now
    puts "Start time: #{begin_time}"
    cred = credential
    queue = Queue.new
    connections = 20
    connections.times.each do |n|
      Thread.new do
        client = TCPSocket.open 'localhost', 2525
        send_mail client, cred, n
        answers = []
        8.times { answers << client.gets.chomp }
        queue.push answers
      end
    end

    timeout = connections / 10 + 10
    while queue.size < connections
      sleep 0.1
      next if (Time.now - begin_time) < timeout

      raise 'Conection timeout!'
    end
    connections.times { expect_answers queue.pop }
    end_time = Time.now
    puts "Stop time: #{end_time}"
    puts("#{connections} connections in: #{(end_time - begin_time).floor}sec")
  end

  it 'receive message with STARTTLS' do
    msg = %(From: Test Sender <test_from_1@example.com>
To: Test Receiver <test_to@example.com>
Subject: Test message
Date: #{Time.now}
This is a test message.)

    smtp = Net::SMTP.new 'localhost', 2525
    smtp.enable_starttls
    smtp.start 'localhost', 'XX', credential.key, :login
    smtp.auth_login 'XX', credential.key
    smtp.send_message msg, 'test_from_1@example.com', 'test_to@example.com'
    res = smtp.finish
    expect(res.string).to eq "221 Closing Connection\n"
  end

  def send_mail(client, cred, msg_id = 1)
    messages = ['HELO', "AUTH PLAIN #{cred.to_smtp_plain}",
                "MAIL FROM:<test_from_#{msg_id}@example.com>",
                'RCPT TO:<test_to@example.com>', 'DATA',
                'From: Test Sender <test_from@example.com',
                'To: "Test Receiver" <test_to@example.com',
                "Date: #{Time.now}", 'Subject: Test messages',
                'Hello Receiver.', 'Hello Receiver.',
                'This is a test message.', 'Bye.', '.', 'QUIT']
    messages.each { |m| client.puts m }
  end

  def expect_answers(answers)
    expectations = ['220 postal.example.com ESMTP Postal',
                    '250 postal.example.com', '235 Granted for org', '250 OK',
                    '250 OK', '354 Go ahead', '250 OK', '221 Closing Connection']
    expectations.each_with_index { |v, i| expect(answers[i]).to include v }
  end
end
