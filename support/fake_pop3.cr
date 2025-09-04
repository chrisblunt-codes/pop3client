# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

require "socket"

module TestSupport
  class FakePOP3
    getter port : Int32

    def initialize(@greeting : String = "+OK test server",
                  @quit_reply : String = "+OK bye")
      @server  = TCPServer.new "127.0.0.1", 0  # ephemeral port
      @port    = (@server.local_address.as(Socket::IPAddress)).port
      @running = true
      spawn accept_loop
    end

    def close
      @running = false
      @server.close rescue nil
    end

    private def accept_loop
      while @running
        if sock = @server.accept?
          # Narrow to non-nil BEFORE spawning
          s = sock.not_nil!
          spawn handle_client(s)
        end
      end
    rescue
      # ignore errors when shutting down
    end

    private def handle_client(sock : TCPSocket)
      sock.puts @greeting
      sock.flush
      while line = sock.gets
        if line.starts_with?("QUIT")
          sock.puts @quit_reply
          sock.flush
          break
        end
      end
      sock.close rescue nil
    end
  end
end