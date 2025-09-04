module Pop3Client
  module Commands
    module List
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
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::List
end
