module Pop3Client
  module Commands
    module Uidl
      # Retrieves unique message identifiers from the POP3 server.
      #
      # If a message number is given, returns the UID for that single message.
      # Otherwise, returns a list of UIDs for all messages.
      #
      # Arguments:
      # * `msg` – (optional) the 1-based message number.
      #
      # Returns:
      # * For a single message: an `Array(String)` with one entry in the form `"n uid"`.
      # * For all messages: an `Array(String)` where each entry is `"n uid"`.
      #
      # Raises:
      # * NotConnectedError – if the client is not connected.
      # * ProtocolError – if the client is not authenticated or the server rejects the command.
      def uidl(msg : Int32? = nil) : Array(String)
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        if msg
          # Single-line response: "+OK <msg> <size>"
          send_line "UIDL #{msg}"

          line = sock!.gets
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
          while line = sock!.gets
            line = line.rstrip
            break if line == "."
            lines << line
          end

          return lines
        end
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Uidl
end
