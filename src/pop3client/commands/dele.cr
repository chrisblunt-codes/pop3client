module Pop3Client
  module Commands
    # Delete messages from the server
    module Dele
      # Deletes a message from the server.
      #
      # Sends a `DELE` command for the given message number. The message will
      # be marked for deletion and removed when the session ends with `QUIT`.
      #
      # * `msg` – 1-based message number to delete.
      #
      # Returns:
      # * The server response line (e.g. `"+OK <msg> deleted"`).
      #
      # Raises:
      # * NotConnectedError – if the client is not connected.
      # * ProtocolError – if the client is not authenticated or the server rejects the command or 
      #   the server does not respond with +OK.
      def dele(msg : Int32) : String
        raise NotConnectedError.new("Not connected") unless connected?
        raise ProtocolError.new("Not authenticated") unless authenticated?

        send_line "DELE #{msg}"

        line = sock!.gets
        raise ProtocolError.new("No response to DELE") unless line
        line = line.rstrip
        raise ProtocolError.new("DELE rejected: #{line}") unless ok?(line)
        line
      end
    end
  end
end

# include into Client

class Pop3Client::Client
  include Pop3Client::Commands::Dele
end
