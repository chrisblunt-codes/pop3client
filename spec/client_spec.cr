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

  it "logs in with valid USER/PASS" do
    fake = TestSupport::FakePOP3.new("+OK hello", valid_user: "bob", valid_pass: "password")

    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      reply = client.login("bob", "password")
      reply.should start_with("+OK")
      client.quit
    ensure
      fake.close
    end
  end

  it "errors if login without connect" do
    client = Pop3Client::Client.new("127.0.0.1", 12345)
    expect_raises(Pop3Client::NotConnectedError) { client.login("user", "pass") }
  end

  it "returns STAT after login" do
    fake = TestSupport::FakePOP3.new("+OK hello", "+OK bye", "user", "pass", 5, 1234_i64)

    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      client.login("user", "pass")
      stat = client.stat
      stat[:count].should eq 5
      stat[:octets].should eq 1234_i64
      client.quit
    ensure
      fake.close
    end
  end 

  it "errors if stat when not authenticated" do
    fake = TestSupport::FakePOP3.new("+OK hello", "+OK bye", "user", "pass")

    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      expect_raises(Pop3Client::ProtocolError) { client.stat }
      client.quit rescue nil
    ensure
      fake.close
    end
  end

  it "lists all messages" do
    fake = TestSupport::FakePOP3.new(messages: [1200, 500, 42])
    
    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      client.login("user", "pass")
      list = client.list
      list.should eq(["1 1200", "2 500", "3 42"])
      client.quit
    ensure
      fake.close
    end
  end

  it "lists one message" do
    fake = TestSupport::FakePOP3.new(messages: [1200, 500, 42])
    
    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      client.login("user", "pass")
      list = client.list 2
      list.should eq(["500"])
      client.quit
    ensure
      fake.close
    end
  end

  it "lists all uids" do
    fake = TestSupport::FakePOP3.new(messages: [1200, 500, 42])
    
    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      client.login("user", "pass")
      list = client.uidl
      list.should eq(["1 UID1-1200", "2 UID2-500", "3 UID3-42"])
      client.quit
    ensure
      fake.close
    end
  end

  it "lists one uid" do
    fake = TestSupport::FakePOP3.new(messages: [1200, 500, 42])
    
    begin
      client = Pop3Client::Client.new("127.0.0.1", fake.port)
      client.connect
      client.login("user", "pass")
      list = client.uidl 1
      list.should eq(["1 UID1-1200"])
      client.quit
    ensure
      fake.close
    end
  end
end
