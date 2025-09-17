# Copyright 2025 Chris Blunt
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
                   @messages : Array(Int32) = [1200, 500, 42],
                   uids : Array(String) = [] of String)

      @uids = (uids.size == @messages.size) ?
                uids :
                @messages.map_with_index { |size, i| "UID#{i + 1}-#{size}" }

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
        when line.starts_with?("USER") then seen_user = handle_user(sock, line)
        when line.starts_with?("PASS") then authed    = handle_pass(sock, line, seen_user)
        when line.starts_with?("STAT") then handle_stat(sock, authed)
        when line.starts_with?("LIST") then handle_list(sock, line, authed)
        when line.starts_with?("UIDL") then handle_uidl(sock, line, authed)
        when line.starts_with?("RETR") then handle_retr(sock, line, authed)
        when line.starts_with?("TOP")  then handle_top(sock, line, authed)
        when line.starts_with?("DELE") then handle_dele(sock, line, authed)
        when line.starts_with?("RSET") then handle_rset(sock, line, authed)
        when line.starts_with?("QUIT") then handle_quit(sock)
        else handle_default(sock, authed)
        end
      end
      
      sock.close rescue nil
    end

    # ---------------------------------------------------------------------
    # Handlers
    # ---------------------------------------------------------------------

    private def handle_user(sock, line) : Bool
      user = line[5..]
      ok = (user == @valid_user)
      sock.puts(ok ? "+OK user accepted" : "-ERR no such user")
      sock.flush
      ok
    end

    private def handle_pass(sock, line, seen_user : Bool) : Bool
      pass = line[5..]
      ok = seen_user && (pass == @valid_pass)
      sock.puts(ok ? "+OK password accepted" : "-ERR invalid password")
      sock.flush
      ok
    end

    private def handle_stat(sock, authed : Bool)
      if authed
        sock.puts "+OK #{@stat_count} #{@stat_octets}"
      else
        sock.puts "-ERR not authenticated"
      end

      sock.flush
    end

    private def handle_list(sock, line, authed : Bool)
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
    end

    private def handle_uidl(sock, line, authed : Bool)
      if authed
        if @messages.empty?
          sock.puts "+OK"
          sock.puts "."
        else
          parts = line.split(" ")
          if parts.size == 2
            idx = parts[1].to_i
            if idx >= 1 && idx <= @uids.size
              sock.puts "+OK #{idx} #{@uids[idx - 1]}"
            else
              sock.puts "-ERR no such message"
            end
          else
            sock.puts "+OK"
            @uids.each_with_index do |uid, i|
              sock.puts "#{i + 1} #{uid}"
            end
            sock.puts "."
          end
        end
      else
        sock.puts "-ERR not authenticated"
      end
      sock.flush
    end

    private def handle_retr(sock, line, authed : Bool)
      unless authed
        sock.puts "-ERR not authenticated"
        sock.flush
        return
      end

      msg = line.split(" ")[1]?.to_s
      if msg == ""
        sock.puts "-ERR no such message"
        sock.flush
        return
      end

      msg_num = msg.to_i
      if msg.to_i < 1 || msg.to_i > @messages.size
        sock.puts "-ERR no such message"
        sock.flush
        return
      end

      size = @messages[msg_num - 1]
      sock.puts "+OK #{size} octets"
      message = test_message(msg_num, size)
      message.each_line { |l| sock.puts l.rstrip }
      sock.puts "."
      sock.flush
    end

    private def handle_top(sock, line, authed : Bool)
      unless authed
        sock.puts "-ERR not authenticated"
        sock.flush
        return
      end

      msg = line.split(" ")[1]?.to_s
      if msg == ""
        sock.puts "-ERR no such message"
        sock.flush
        return
      end

      msg_num = msg.to_i
      if msg.to_i < 1 || msg.to_i > @messages.size
        sock.puts "-ERR no such message"
        sock.flush
        return
      end

      max_lines = line.split(" ")[2]?.to_s
      max_lines = if max_lines != ""
                    max_lines.to_i
                  else 
                    100
                  end

      size = @messages[msg_num - 1]
      sock.puts "+OK #{size} octets"

      line_num = 1
      message  = test_message(msg_num, size)

      message.each_line do |line|        
        if line_num <= max_lines
          sock.puts line.rstrip   
        end
        line_num += 1
      end

      sock.puts "."
      sock.flush
    end

    private def handle_dele(sock, line, authed : Bool)
      unless authed
        sock.puts "-ERR not authenticated"
        sock.flush
        return
      end

      msg = line.split(" ")[1]?.to_s
      if msg == ""
        sock.puts "-ERR no such message"
        sock.flush
        return
      end

      msg_num = msg.to_i
      if msg.to_i < 1 || msg.to_i > @messages.size
        sock.puts "-ERR no such message"
        sock.flush
        return
      end

      sock.puts "+OK message #{msg_num} deleted"
      sock.flush
    end

    private def handle_rset(sock, line, authed : Bool)
      unless authed
        sock.puts "-ERR not authenticated"
        sock.flush
        return
      end

      sock.puts "+OK reset"
      sock.flush
    end

    private def handle_quit(sock)
      sock.puts @quit_reply
      sock.flush
    end

    private def handle_default(sock, authed : Bool)
      # default: say OK to unknown if authed, else -ERR
      if authed
        sock.puts "+OK"
      else
        sock.puts "-ERR not authenticated"  
      end
      sock.flush
    end

    # ---------------------------------------------------------------------
    # Helpers
    # ---------------------------------------------------------------------

    private def test_message(msg_num : Int32 = 1, size : Int64 = 100_000) : String
      <<-MSG
From: test@example.com
To: user@example.com
Subject: Test message #{msg_num}

..QUOTE:
I must not fear. Fear is the mind-killer. 
Fear is the little-death that brings total obliteration.
I will face my fear. I will permit it to pass over me and through me. 
And when it has gone past I will turn the inner eye to see its path. 
Where the fear has gone there will be nothing. 
Only I will remain.

This is the body of message #{msg_num}, size #{size} octets.
MSG
    end
  end
end