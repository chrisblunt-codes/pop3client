# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

require "./spec_helper"

require "../support/fake_pop3"
require "../src/pop3client"

describe Pop3Client::Client do
  it "connects and reads +OK greeting" do
    fake = TestSupport::FakePOP3.new("+OK hello")
    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      greeting = client.connect
      greeting.should start_with("+OK")
      client.quit.should start_with("+OK")
      client.connected?.should be_false
    ensure
      fake.close
    end
  end

  it "errors if quitting while not connected" do
    client = Pop3Client::Client.new("127.0.0.1", 12345)
    expect_raises(Pop3Client::NotConnectedError) { client.quit }
  end  

  it "errors if connecting while already connected" do
    fake = TestSupport::FakePOP3.new("+OK hello")
    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      expect_raises(Pop3Client::AlreadyConnectedError) { client.connect }
    ensure
      fake.close
    end
  end
end
