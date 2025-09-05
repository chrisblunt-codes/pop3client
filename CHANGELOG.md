# Changelog

All notable changes to this project will be documented in this file.  
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]
### Added
- (nothing yet)

### Changed
- (nothing yet)

### Fixed
- (nothing yet)

---

## [0.2.0] - 2025-09-05
### Added
- USER/PASS authentication (`Client#login`)
- STAT support (`Client#stat`) returning `{count: Int32, octets: Int64}`
- LIST support (`Client#list`) returning `Array(String)`
- UIDL support (`Client#uidl`) returning `Array(String)`
- RETR support (`Client#retr`) returning `String`
- TOP support  (`Client#top`)  returning `String`
- DELE support (`Client#dele`) returning `String`
- RSET support (`Client#rset`) returning `String`

## [0.1.0] - 2025-09-04
### Added
- Connect to a POP3 server
- Read greeting response (`+OK`)
- Send `QUIT` and close connection
- Basic error handling (`ProtocolError`, `ConnectionError`, etc.)
- Minimal example and spec suite included

---

Copyright 2025 Chris Blunt  
Licensed under the Apache License, Version 2.0

---

[Unreleased]: https://github.com/chrisblunt-codes/pop3client/compare/v0.1.0...HEAD  
[0.1.0]: https://github.com/chrisblunt-codes/pop3client/releases/tag/v0.1.0
