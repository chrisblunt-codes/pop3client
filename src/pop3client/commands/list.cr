module Pop3Client
  module Commands
    module List
      # Retrieves message sizes from the POP3 server.
      #
      # If a message number is given, returns the size for that single message.
      # Otherwise, returns a list of all messages and their sizes.
      #
      # Arguments:
      # * `msg` – (optional) the 1-based message number.
      #
      # Returns:
      # * For a single message: an `Array(String)` with one entry in the form `"n size"`.
      # * For all messages: an `Array(String)` where each entry is `"n size"`.
      #
      # Raises:
      # * NotConnectedError – if the client is not connected.
      # * ProtocolError – if the client is not authenticated or the server rejects the command.
      def list(msg : Int32? = nil) : Array(String)
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        if msg
          # Single-line response: "+OK <msg> <size>"
          send_line "LIST #{msg}"

          line = sock!.gets
          raise ProtocolError.new("No response to LIST") unless line
          line = line.rstrip

          raise ProtocolError.new("LIST rejected: #{line}") unless ok?(line)

          # Return just "msg size" for consistency with multi-line form
          return [line.sub(/\A\+OK\s+/, "")]
        else
          # Multi-line response: first status line, then "n size" lines, then "."
          send_line "LIST"

          status = sock!.gets
          raise ProtocolError.new("No response to LIST") unless status
          status = status.rstrip
          raise ProtocolError.new("LIST rejected: #{status}") unless ok?(status)

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
  include Pop3Client::Commands::List
end
