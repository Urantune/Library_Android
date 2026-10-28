package customer.identityservice.auth.persistence;

import customer.identityservice.auth.dto.SessionResponse.UserView;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class AuthRepository {
    public record Account(String id, String email, String name, String passwordHash, String status) {}
    public record RefreshRow(String id, String userId, String sessionId, String expiresAt, String revokedAt) {}
    private final JdbcTemplate jdbc;

    public AuthRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public Optional<Account> findByEmail(String email) {
        return jdbc.query("SELECT id,email,full_name,password_hash,status FROM users WHERE lower(email)=?",
            (rs,n) -> new Account(rs.getString(1),rs.getString(2),rs.getString(3),rs.getString(4),rs.getString(5)), email).stream().findFirst();
    }

    public Account account(String id) {
        return jdbc.queryForObject("SELECT id,email,full_name,password_hash,status FROM users WHERE id=?",
            (rs,n) -> new Account(rs.getString(1),rs.getString(2),rs.getString(3),rs.getString(4),rs.getString(5)), id);
    }

    public UserView view(String id) {
        Account user = account(id);
        List<String> roles = jdbc.queryForList("SELECT r.code FROM roles r JOIN user_roles ur ON ur.role_id=r.id WHERE ur.user_id=? ORDER BY r.code",String.class,id);
        return new UserView(user.id(),user.email(),user.name(),roles,user.status());
    }

    public void insertUser(String id, String email, String name, String hash, Instant now) {
        jdbc.update("INSERT INTO users(id,email,password_hash,full_name,status,created_at,updated_at) VALUES(?,?,?,?,'ACTIVE',?,?)",
            id,email,hash,name,now.toString(),now.toString());
        jdbc.update("INSERT INTO user_roles(user_id,role_id,assigned_at) SELECT ?,id,? FROM roles WHERE code='MEMBER'",id,now.toString());
    }

    public void createSession(String id, String userId, Instant expires, Instant now) {
        jdbc.update("INSERT INTO auth_sessions(id,user_id,expires_at,created_at) VALUES(?,?,?,?)",id,userId,expires.toString(),now.toString());
        jdbc.update("UPDATE users SET last_login_at=? WHERE id=?",now.toString(),userId);
    }

    public void insertRefresh(String id, String userId, String sessionId, String hash, Instant expires, Instant now) {
        jdbc.update("INSERT INTO refresh_tokens(id,user_id,session_id,token_hash,expires_at,created_at) VALUES(?,?,?,?,?,?)",
            id,userId,sessionId,hash,expires.toString(),now.toString());
    }

    public Optional<RefreshRow> findRefresh(String hash) {
        return jdbc.query("SELECT id,user_id,session_id,expires_at,revoked_at FROM refresh_tokens WHERE token_hash=?",
            (rs,n) -> new RefreshRow(rs.getString(1),rs.getString(2),rs.getString(3),rs.getString(4),rs.getString(5)),hash).stream().findFirst();
    }

    public boolean consumeRefresh(String id, Instant now) {
        return jdbc.update("UPDATE refresh_tokens SET revoked_at=? WHERE id=? AND revoked_at IS NULL AND expires_at>?",
            now.toString(),id,now.toString()) == 1;
    }

    public boolean activeSession(String sessionId, String userId, Instant now) {
        if (sessionId == null || userId == null) return false;
        return jdbc.queryForObject("SELECT COUNT(*) FROM auth_sessions s JOIN users u ON u.id=s.user_id WHERE s.id=? AND s.user_id=? AND s.revoked_at IS NULL AND s.expires_at>? AND u.status='ACTIVE'",
            Integer.class,sessionId,userId,now.toString()) == 1;
    }

    public void revokeSession(String id, Instant now) {
        jdbc.update("UPDATE auth_sessions SET revoked_at=COALESCE(revoked_at,?) WHERE id=?",now.toString(),id);
        jdbc.update("UPDATE refresh_tokens SET revoked_at=COALESCE(revoked_at,?) WHERE session_id=?",now.toString(),id);
    }
}
