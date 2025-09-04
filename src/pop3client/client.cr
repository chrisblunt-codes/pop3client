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
