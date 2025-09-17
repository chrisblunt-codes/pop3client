# Copyright 2025 Chris Blunt
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

module Pop3Client
  module Commands
    module Top
      # Retrieves message headers and a limited number of body lines.
      #
      # Sends the `TOP` command for the given message number and returns the
      # complete headers plus up to `lines` lines of the message body.
      # Dot-stuffing is automatically removed.
      #
      # Arguments:
      # * `msg` – the 1-based message number to retrieve.
      # * `lines` – the number of body lines to include after the headers.
      #
      # Returns:
      # * A `String` containing the headers and the requested number of body lines.
      #
      # Raises:
      # * NotConnectedError – if the client is not connected.
      # * ProtocolError – if the client is not authenticated, the server
      #   rejects the request, or the response is malformed.
      def top(msg : Int32, lines : Int32) : String
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "TOP #{msg} #{lines}"

        line = sock!.gets
        raise ProtocolError.new("No response to RETR") unless line
        line = line.rstrip
        raise ProtocolError.new("TOP rejected: #{line}") unless ok?(line)
        
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
  include Pop3Client::Commands::Top
end
