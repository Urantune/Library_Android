package customer.identityservice.auth.security;

import com.nimbusds.jose.jwk.*;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import customer.identityservice.auth.dto.SessionResponse.UserView;
import java.time.Clock;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Component;

@Component
public class AuthTokens {
    private final JwtEncoder encoder;
    private final Clock clock;
    private final String issuer;
    private final String audience;
    private final long lifetime;

    public AuthTokens(AuthSigningKeys keys, Clock clock,
        @Value("${app.auth.issuer:library-identity}") String issuer,
        @Value("${app.auth.audience:library-api}") String audience,
        @Value("${app.auth.access-seconds:900}") long lifetime) {
        encoder=new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(new RSAKey.Builder(keys.publicKey()).privateKey(keys.privateKey()).keyID("identity").build())));
        this.clock=clock; this.issuer=issuer; this.audience=audience; this.lifetime=lifetime;
    }

    public String access(UserView user, String sessionId) {
        var now=clock.instant();
        var claims=JwtClaimsSet.builder().issuer(issuer).audience(List.of(audience)).subject(user.id())
            .issuedAt(now).expiresAt(now.plusSeconds(lifetime)).id(UUID.randomUUID().toString())
            .claim("sid",sessionId).claim("roles",user.roles()).build();
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(SignatureAlgorithm.RS256).keyId("identity").build(),claims)).getTokenValue();
    }
    public long lifetime() { return lifetime; }
}
