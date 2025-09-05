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
  puts "> LIST"
  list = client.list
  list.each do |line|
    puts line
  end

  # retr message 1
  puts "> DELE 1"
  line = client.dele(1)
  puts line

  # rset
  puts "> RSET"
  line = client.rset
  puts line

  puts client.quit
  puts "Connected after QUIT? #{client.connected?}"
ensure
  fake.close
end

