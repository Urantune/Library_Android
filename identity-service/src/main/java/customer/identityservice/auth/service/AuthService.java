package customer.identityservice.auth.service;

import customer.identityservice.auth.dto.AuthRequests;
import customer.identityservice.auth.dto.SessionResponse;
import customer.identityservice.auth.dto.SessionResponse.UserView;
import customer.identityservice.auth.persistence.AuthRepository;
import customer.identityservice.auth.security.AuthTokens;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(noRollbackFor=AuthException.class)
public class AuthService {
    private final AuthRepository repository;
    private final PasswordEncoder passwords;
    private final AuthTokens tokens;
    private final AuthThrottle throttle;
    private final Clock clock;
    private final long refreshSeconds;
    private final String dummyHash;
    private final SecureRandom random=new SecureRandom();

    public AuthService(AuthRepository repository, PasswordEncoder passwords, AuthTokens tokens,
        AuthThrottle throttle, Clock clock, @Value("${app.auth.refresh-seconds:604800}") long refreshSeconds) {
        this.repository=repository;this.passwords=passwords;this.tokens=tokens;this.throttle=throttle;this.clock=clock;this.refreshSeconds=refreshSeconds;
        dummyHash=passwords.encode(UUID.randomUUID().toString());
    }

    public UserView register(AuthRequests.Register input) {
        String email=normalize(input.email());
        String name=input.fullName().trim();
        if (name.length()<2 || name.codePoints().anyMatch(Character::isISOControl)) throw invalid("fullName","Họ tên không hợp lệ.");
        if (input.password().getBytes(StandardCharsets.UTF_8).length>72) throw invalid("password","Mật khẩu không được vượt quá 72 byte UTF-8.");
        if (repository.findByEmail(email).isPresent()) throw new AuthException(409,"EMAIL_EXISTS","Email đã được đăng ký.");
        String id=UUID.randomUUID().toString();
        repository.insertUser(id,email,name,passwords.encode(input.password()),clock.instant());
        return repository.view(id);
    }

    public SessionResponse login(AuthRequests.Login input) {
        String email=normalize(input.email());
        throttle.checkAccount(email);
        var account=repository.findByEmail(email);
        boolean matches=input.password().getBytes(StandardCharsets.UTF_8).length<=72
            && passwords.matches(input.password(),account.map(AuthRepository.Account::passwordHash).orElse(dummyHash));
        if (!matches || account.isEmpty() || !"ACTIVE".equals(account.get().status())) {
            throttle.failedLogin(email);
            throw new AuthException(401,"INVALID_CREDENTIALS","Email hoặc mật khẩu không đúng.");
        }
        throttle.clearAccount(email);
        String session=UUID.randomUUID().toString();
        var now=clock.instant();
        repository.createSession(session,account.get().id(),now.plusSeconds(refreshSeconds),now);
        return issue(account.get().id(),session,now);
    }

    public SessionResponse refresh(String rawToken) {
        var now=clock.instant();
        var stored=repository.findRefresh(AuthThrottle.hash(rawToken)).orElseThrow(this::expired);
        if (stored.revokedAt()!=null) {
            if (stored.sessionId()!=null) repository.revokeSession(stored.sessionId(),now);
            throw expired();
        }
        if (!repository.activeSession(stored.sessionId(),stored.userId(),now) || !repository.consumeRefresh(stored.id(),now)) throw expired();
        return issue(stored.userId(),stored.sessionId(),now);
    }

    public void logout(String sessionId) { repository.revokeSession(sessionId,clock.instant()); }

    private SessionResponse issue(String userId, String sessionId, Instant now) {
        byte[] bytes=new byte[32];random.nextBytes(bytes);
        String refresh=Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        repository.insertRefresh(UUID.randomUUID().toString(),userId,sessionId,AuthThrottle.hash(refresh),now.plusSeconds(refreshSeconds),now);
        var user=repository.view(userId);
        return new SessionResponse(tokens.access(user,sessionId),refresh,"Bearer",tokens.lifetime(),user);
    }

    private String normalize(String email) { return email.trim().toLowerCase(Locale.ROOT); }
    private AuthException expired() { return new AuthException(401,"SESSION_EXPIRED","Phiên đăng nhập không hợp lệ hoặc đã hết hạn."); }
    private AuthException invalid(String field,String message) { return new AuthException(400,"INVALID_INPUT",message,Map.of(field,message),0); }
}
