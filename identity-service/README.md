# Identity authentication

Java 21, Spring Security, RSA JWT, BCrypt and SQLite. From the server root run `powershell -ExecutionPolicy Bypass -File .\run-auth.ps1`; default port 8081. No Gateway, Eureka, Redis or Kafka is required for this local auth flow. Existing domain services remain separate.

Persistent files: `identity-service/data/identity.db` and `data/auth-keys/private.pem` plus `public.pem`. Do not commit, print or share the private key. Keep the database and keys across restarts. Override DB_PATH and AUTH_KEY_DIR for a deployment, using a protected secret mount for the key directory. Public key export supports later Gateway integration.

| API | Request | Result |
|---|---|---|
| POST /api/auth/register | email, password, fullName | 201 user; always MEMBER; then login |
| POST /api/auth/login | email, password | accessToken, refreshToken, expiresIn, user |
| POST /api/auth/refresh | refreshToken | rotated token pair |
| GET /api/users/me | Authorization: Bearer accessToken | signed-in user |
| POST /api/auth/logout | Authorization: Bearer accessToken | 204; session and its refresh tokens revoked |

Password: 8–72 characters and at most 72 UTF-8 bytes on registration. Access lifetime 15 minutes; session/refresh lifetime at most 7 days. Refresh reuse revokes that session family. This service validates the persisted session on authenticated calls, so logout revokes access immediately **inside Identity**. Other services/Gateway must integrate their authorization and revocation checks separately; this change does not claim to secure every domain API.

Request body limit: 8 KiB. Login: 30 requests/IP/minute and 5 failed attempts/account/5 minutes; registration: 5 requests/IP/hour; refresh/logout: 60 requests/IP/minute. State persists in SQLite; 429 includes Retry-After. Remote IP is obtained from the connection; arbitrary X-Forwarded-For is ignored. A future trusted proxy must explicitly configure forwarded address handling. This is application-level throttling for the single-instance SQLite deployment, not volumetric DDoS protection.

Error responses contain status/code/message/fieldErrors/traceId without stack traces, passwords or tokens. Login failure is generic. JDBC values are bound parameters. Client roles are ignored on registration. CSRF cookies are not used: authentication is stateless Bearer-header based. Production requires HTTPS; Android cleartext permission is enabled only for debug/profile builds.

Android emulator defaults to `http://10.0.2.2:8081`; desktop/web defaults to `http://127.0.0.1:8081`. Override using `flutter run --dart-define=AUTH_BASE_URL=http://your-host:8081`; a physical device needs the host LAN address. When Gateway is available, change AUTH_BASE_URL to its URL. The app persists only tokens when Remember is checked and keeps them in memory otherwise. No mock-account fallback is used.

Tests: `mvnw.cmd test` in this module (temporary SQLite DBs under target). Security rationale follows [OWASP authentication guidance](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html) and [Spring Security JWT validation](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html).
