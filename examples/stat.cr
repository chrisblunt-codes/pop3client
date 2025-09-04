# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

require "../src/pop3client"
require "../support/fake_pop3"


fake = TestSupport::FakePOP3.new(stat_count: 5, stat_octets: 1234_i64)

begin
  puts "Connecting to 127.0.0.1:#{fake.port}..."
  client = Pop3Client::Client.new("127.0.0.1", fake.port)
  puts client.connect
  puts client.login("user", "pass")
  stat = client.stat
  puts "STAT: #{stat[:count]} messages, #{stat[:octets]} octets"
  puts client.quit
  puts "Connected after QUIT? #{client.connected?}"
ensure
  fake.close
end

