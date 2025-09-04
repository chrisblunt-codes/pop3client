# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

require "../src/pop3client"
require "../support/fake_pop3"


fake = TestSupport::FakePOP3.new(messages: [1200, 500, 42])

begin
  puts "Connecting to 127.0.0.1:#{fake.port}..."
  client = Pop3Client::Client.new("127.0.0.1", fake.port)
  puts client.connect
  puts client.login("user", "pass")

  # list all messages
  puts "> UIDL"
  list = client.uidl
  list.each do |line|
    puts line
  end

  # list message 1
  puts "> UIDL 1"
  list = client.uidl(1)
  list.each do |line|
    puts line
  end
  puts client.quit
  puts "Connected after QUIT? #{client.connected?}"
ensure
  fake.close
end

