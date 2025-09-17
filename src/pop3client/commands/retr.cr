# Copyright 2025 Chris Blunt
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

module Pop3Client
  module Commands
    module Retr
      # Retrieves a full message from the POP3 server.
      #
      # Sends a `RETR` command for the given message number and returns the
      # complete message text, including headers and body. Dot-stuffing is
      # automatically removed.
      #
      # Arguments:
      # * `msg` – the 1-based message number to retrieve.
      #
      # Returns:
      # * A `String` containing the full message text with CRLF line endings.
      #
      # Raises:
      # * NotConnectedError – if the client is not connected.
      # * ProtocolError – if the client is not authenticated, the server
      #   rejects the request, or the response is malformed.
      def retr(msg : Int32) : String
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "RETR #{msg}"

        line = sock!.gets
        raise ProtocolError.new("No response to RETR") unless line
        line = line.rstrip
        raise ProtocolError.new("RETR rejected: #{line}") unless ok?(line)
        
        io = IO::Memory.new
        while(line = sock!.gets)
          line = line.rstrip
          break if line == "."
          
          # Unstuff: if the line begins with "..", drop the first dot
          line = line[1..] if line.starts_with?("..")
          
          io << line << "\r\n"
        end

        return io.to_s
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Retr
end
