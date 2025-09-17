# Copyright 2025 Chris Blunt
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

require "../src/pop3client"
require "../support/fake_pop3"


fake = TestSupport::FakePOP3.new(valid_user: "user", valid_pass: "pass")

begin
  puts "Connecting to 127.0.0.1:#{fake.port}..."
  client = Pop3Client::Client.new("127.0.0.1", fake.port)
  puts client.connect
  puts client.login("user", "pass")
  puts client.quit
  puts "Connected after QUIT? #{client.connected?}"
ensure
  fake.close
end

