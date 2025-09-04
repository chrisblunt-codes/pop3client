# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

require "socket"

module TestSupport
  class FakePOP3
    getter port : Int32

    def initialize(@greeting : String = "+OK test server",
                   @quit_reply : String = "+OK bye",
                   @valid_user : String = "user",
                   @valid_pass : String = "pass",
                   @stat_count : Int32 = 2,
                   @stat_octets : Int64 = 1234_i64,
                   @messages : Array(Int32) = [1200, 500, 42])

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
      authed    = false
      seen_user = false

      sock.puts @greeting
      sock.flush

      while line = sock.gets
        line = line.rstrip

        case
        when line.starts_with?("USER")
          user = line[5..]
          seen_user = (user == @valid_user)
          if seen_user
            sock.puts "+OK user accepted"
          else
            sock.puts "-ERR no such user"
          end
          sock.flush

        when line.starts_with?("PASS")
          pass = line[5..]

          if seen_user && (pass == @valid_pass)
            authed = true
            sock.puts "+OK password accepted"
          else
            sock.puts "-ERR invalid password"
          end

          sock.flush
        
        when line.starts_with?("STAT")
          if authed
            sock.puts "+OK #{@stat_count} #{@stat_octets}"
          else
            sock.puts "-ERR not authenticated"
          end

          sock.flush

        when line.starts_with?("LIST")
          if authed
            if @messages.empty?
              sock.puts "+OK 0 0"
            else
              msg = line.split(" ")[1]?.to_s
              if msg != ""
                sock.puts "+OK #{@messages[msg.to_i - 1]}"
              else
                sock.puts "+OK #{@messages.size} #{@messages.sum}"

                @messages.each_with_index do |msg, idx|
                  sock.puts "#{idx + 1} #{msg}"
                end
                sock.puts "."
              end
            end

          else
            sock.puts "-ERR not authenticated"
          end

          sock.flush

        when line.starts_with?("QUIT")
          sock.puts @quit_reply
          sock.flush

        else
          # default: say OK to unknown if authed, else -ERR
          if authed
            sock.puts "+OK"
          else
            sock.puts "-ERR not authenticated"  
          end
          sock.flush
        end
      end
      sock.close rescue nil
    end
  end
end