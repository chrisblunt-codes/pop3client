# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

require "socket"

module Pop3Client
  class Client
    getter host : String
    getter port : Int32
    getter read_timeout  : Time::Span
    getter write_timeout : Time::Span
    
    setter read_timeout
    setter write_timeout

    @socket : TCPSocket?

    def initialize(@host : String, @port : Int32 = 110)
      @read_timeout   = 10.seconds
      @write_timeout  = 10.seconds
    end

    def connect : String
      raise AlreadyConnectedError.new("Already connected") if connected?
      create_socket 

      line = read_line
      unless ok?(line)
        close
        raise ProtocolError.new("Server did not respond with +OK: #{line}")
      end

      line
    end

    def login(username : String, password : String) : String
      raise NotConnectedError.new("Not connected") unless connected?

      send_line "USER #{username}"
      line = read_line
      unless ok?(line)
        close
        raise ProtocolError.new("USER rejected: #{line}")
      end

      send_line "PASS #{password}"
      line = read_line
      unless ok?(line)
        close
        raise ProtocolError.new("PASS rejected:#{line}")
      end
      
      @authenticated = true
      line
    end

    def connected? : Bool
      !@socket.nil?
    end

    def authenticated? : Bool
      !@authenticated.nil? && @authenticated == true
    end

    def stat : NamedTuple(count: Int32, octets: Int64)
      raise NotConnectedError.new("Not connected") unless connected?
      raise ProtocolError.new("Not authenticated") unless authenticated?

      send_line "STAT"
      line = read_line

      unless ok?(line)
        close
        raise ProtocolError.new("STAT rejected: #{line}")
      end

      # Expect "+OK <count> <octets>"
      parts = line.split
      
      # parts[0]="+OK", parts[1]=count, parts[2]=octets
      if parts.size < 3
        raise ProtocolError.new("Malformed STAT response: #{line}")
      end

      count  = parts[1].to_i? || raise ProtocolError.new("Bad count in STAT: #{parts[1]}")
      octets = parts[2].to_i64? || raise ProtocolError.new("Bad octets in STAT: #{parts[2]}")

      { count: count, octets: octets }
    end

    def list(msg : Int32? = nil) : Array(String)
      raise NotConnectedError.new("Not connected") unless connected?
      raise ProtocolError.new("Not authenticated") unless authenticated?

      if msg
        # Single-line response: "+OK <msg> <size>"
        send_line "LIST #{msg}"

        line = @socket.not_nil!.gets
        raise ProtocolError.new("No response to LIST") unless line
        line = line.rstrip

        raise ProtocolError.new("LIST rejected: #{line}") unless ok?(line)

        # Return just "msg size" for consistency with multi-line form
        return [line.sub(/\A\+OK\s+/, "")]
      else
        # Multi-line response: first status line, then "n size" lines, then "."
        send_line "LIST"

        status = @socket.not_nil!.gets
        raise ProtocolError.new("No response to LIST") unless status
        status = status.rstrip
        raise ProtocolError.new("LIST rejected: #{status}") unless ok?(status)

        lines = [] of String
        while line = @socket.not_nil!.gets
          line = line.rstrip
          break if line == "."
          lines << line
        end

        return lines
      end
    end

    def uidl(msg : Int32? = nil) : Array(String)
      raise NotConnectedError.new("Not connected") unless connected?
      raise ProtocolError.new("Not authenticated") unless authenticated?

      if msg
        # Single-line response: "+OK <msg> <size>"
        send_line "UIDL #{msg}"

        line = @socket.not_nil!.gets
        raise ProtocolError.new("No response to UIDL") unless line
        line = line.rstrip

        raise ProtocolError.new("UIDL rejected: #{line}") unless ok?(line)

        # Return just "msg size" for consistency with multi-line form
        return [line.sub(/\A\+OK\s+/, "")]
      else
        # Multi-line response: first status line, then "n size" lines, then "."
        send_line "UIDL"

        status = @socket.not_nil!.gets
        raise ProtocolError.new("No response to UIDL") unless status
        status = status.rstrip
        raise ProtocolError.new("UIDL rejected: #{status}") unless ok?(status)

        lines = [] of String
        while line = @socket.not_nil!.gets
          line = line.rstrip
          break if line == "."
          lines << line
        end

        return lines
      end
    end

    def quit : String
      send_line "QUIT"
      line = read_line
      close
      line
    end

    def close
      @socket.try &.close
      @socket = nil
    end

    private def create_socket
      sock = TCPSocket.new(@host, @port)
      sock.read_timeout  = @read_timeout
      sock.write_timeout = @write_timeout

      @socket = sock
    rescue e
      close
      raise ConnectionError.new(e.message)
    end

    private def read_line : String
      line = sock!.gets || raise ProtocolError.new("Unexpected EOF")
      line.rstrip
    end

    private def ok?(line : String) : Bool
      line.starts_with?("+OK")
    end

    private def send_line(s : String) : Nil
      sock! << s << "\r\n"
      sock!.flush
    end

    private def sock! : TCPSocket
      @socket || raise NotConnectedError.new("Not connected")
    end
  end
end
