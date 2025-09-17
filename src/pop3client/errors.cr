# Copyright 2025 Chris Blunt
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

module Pop3Client
  class AlreadyConnectedError < Exception; end
  class ConnectionError       < Exception; end
  class NotConnectedError     < Exception; end
  class Pop3Error             < Exception; end
  class ProtocolError         < Pop3Error; end
  class ResponseError         < Pop3Error; end
end
