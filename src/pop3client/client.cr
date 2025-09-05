# Copyright 2025 Chris Blunt
# Licensed under the Apache License, Version 2.0

require "socket"

module Pop3Client
  # A tiny POP3 client.
  class Client

    # Host address of the POP3 server.
    getter host : String

    # Port number of the POP3 server.
    getter port : Int32

    # Socket read timeout (default: 10 seconds).
    getter read_timeout : Time::Span
    setter read_timeout

    # Socket write timeout (default: 10 seconds).
    getter write_timeout : Time::Span
    setter write_timeout

    # Underlying TCP socket (nil if not connected).
    @socket : TCPSocket?

    # Creates a new POP3 client.
    #
    # By default, the client connects on port `110` with a read and write
    # timeout of 10 seconds each.
    #
    # Arguments:
    # * `host` – the POP3 server hostname or IP address.
    # * `port` – (optional) the port number to connect to (default: `110`).
    def initialize(@host : String, @port : Int32 = 110)
      @read_timeout   = 10.seconds
      @write_timeout  = 10.seconds
    end

    # Connects to the POP3 server.
    #
    # Establishes a TCP connection and reads the server's initial greeting.
    #
    # Returns:
    # * The server greeting line (e.g. `"+OK POP3 server ready"`).
    #
    # Raises:
    # * AlreadyConnectedError – if the client is already connected.
    # * ProtocolError – if the server does not respond with `+OK`.
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

    # Authenticates with the POP3 server.
    #
    # Sends `USER` and `PASS` commands to log in with the given credentials.
    #
    # Arguments:
    # * `username` – the account username.
    # * `password` – the account password.
    #
    # Returns:
    # * The server response to the `PASS` command (e.g. `"+OK User successfully logged on"`).
    #
    # Raises:
    # * NotConnectedError – if the client is not connected.
    # * ProtocolError – if the server rejects `USER` or `PASS`.
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

    # Checks whether the client is currently connected to the POP3 server.
    #
    # Returns:
    # * `true` if a TCP connection is open.
    # * `false` otherwise.
    def connected? : Bool
      !@socket.nil?
    end

    # Checks whether the client is authenticated with the POP3 server.
    #
    # Returns:
    # * `true` if the client has successfully logged in with `USER`/`PASS`.
    # * `false` otherwise.
    def authenticated? : Bool
      !@authenticated.nil? && @authenticated == true
    end

    # Disconnects from the POP3 server.
    #
    # Sends the `QUIT` command, closes the connection, and returns the
    # server’s final response.
    #
    # Returns:
    # * The server response to the `QUIT` command (e.g. `"+OK bye"`).
    def quit : String
      send_line "QUIT"
      line = read_line
      close
      line
    end

    # Closes the connection to the POP3 server without sending `QUIT`.
    #
    # This immediately closes the underlying socket and clears `@socket`.
    # Use `quit` instead if you want to gracefully notify the server.
    def close
      @socket.try &.close
      @socket = nil
    end

    # Creates a new TCP socket connection to the POP3 server.
    #
    # By default, the socket uses a 10-second read and write timeout,
    # which can be overridden via the `read_timeout` and `write_timeout` properties.
    #
    # Returns:
    # * `nil` – the new socket is stored in `@socket`.
    #
    # Raises:
    # * ConnectionError – if the connection attempt fails.
    private def create_socket
      sock = TCPSocket.new(@host, @port)
      sock.read_timeout  = @read_timeout
      sock.write_timeout = @write_timeout

      @socket = sock
    rescue e
      close
      raise ConnectionError.new(e.message)
    end


    # Reads a single line from the server.
    #
    # Trailing CRLF is stripped before returning.
    #
    # Returns:
    # * The server response line as a `String`.
    #
    # Raises:
    # * ProtocolError – if the connection is closed unexpectedly (EOF).
    private def read_line : String
      line = sock!.gets || raise ProtocolError.new("Unexpected EOF")
      line.rstrip
    end

    # Checks whether a server response indicates success.
    #
    # Returns:
    # * `true` if the line begins with `+OK`.
    # * `false` otherwise.
    private def ok?(line : String) : Bool
      line.starts_with?("+OK")
    end

    # Sends a command line to the POP3 server.
    #
    # Appends CRLF (`\r\n`) to the string before sending and flushes the socket.
    #
    # Returns:
    # * `nil`
    private def send_line(s : String) : Nil
      sock! << s << "\r\n"
      sock!.flush
    end

    # Returns the active socket connection to the POP3 server.
    #
    # Returns:
    # * The current `TCPSocket`.
    #
    # Raises:
    # * NotConnectedError – if no connection is open.
    private def sock! : TCPSocket
      @socket || raise NotConnectedError.new("Not connected")
    end
  end
end
