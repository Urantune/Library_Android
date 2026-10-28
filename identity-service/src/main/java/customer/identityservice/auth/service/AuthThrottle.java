package customer.identityservice.auth.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.util.HexFormat;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthThrottle {
    private final JdbcTemplate jdbc;
    private final Clock clock;

    public AuthThrottle(JdbcTemplate jdbc, Clock clock) { this.jdbc=jdbc; this.clock=clock; }

    @Transactional(noRollbackFor=AuthException.class)
    public void consume(String key, int limit, long seconds) {
        long now = clock.instant().getEpochSecond();
        jdbc.update("DELETE FROM auth_throttle WHERE ends_at<=?",now);
        jdbc.update("INSERT INTO auth_throttle(bucket_key,attempts,ends_at) VALUES(?,1,?) ON CONFLICT(bucket_key) DO UPDATE SET attempts=CASE WHEN ends_at<=? THEN 1 ELSE attempts+1 END, ends_at=CASE WHEN ends_at<=? THEN excluded.ends_at ELSE ends_at END",
            key,now+seconds,now,now);
        var row = jdbc.queryForMap("SELECT attempts,ends_at FROM auth_throttle WHERE bucket_key=?",key);
        if (((Number)row.get("attempts")).intValue()>limit) limited(((Number)row.get("ends_at")).longValue()-now);
    }

    public void checkAccount(String email) {
        long now=clock.instant().getEpochSecond();
        var rows=jdbc.queryForList("SELECT attempts,ends_at FROM auth_throttle WHERE bucket_key=? AND ends_at>?", "account:"+hash(email),now);
        if (!rows.isEmpty() && ((Number)rows.getFirst().get("attempts")).intValue()>=5) {
            limited(((Number)rows.getFirst().get("ends_at")).longValue()-now);
        }
    }

    public void failedLogin(String email) { consume("account:"+hash(email),5,300); }
    public void clearAccount(String email) { jdbc.update("DELETE FROM auth_throttle WHERE bucket_key=?", "account:"+hash(email)); }

    private void limited(long seconds) {
        throw new AuthException(429,"RATE_LIMITED","Thao tác quá nhiều lần. Vui lòng thử lại sau.",Map.of(),Math.max(1,seconds));
    }

    public static String hash(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) { throw new IllegalStateException(ex); }
    }
}
