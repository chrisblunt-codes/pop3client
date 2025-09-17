# Copyright 2025 Chris Blunt
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

  # list message 1
  puts "> LIST 1"
  list = client.list(1)
  list.each do |line|
    puts line
  end
  puts client.quit
  puts "Connected after QUIT? #{client.connected?}"
ensure
  fake.close
end

