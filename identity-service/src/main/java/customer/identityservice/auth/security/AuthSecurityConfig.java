package customer.identityservice.auth.security;

import customer.identityservice.auth.persistence.AuthRepository;
import customer.identityservice.auth.service.AuthThrottle;
import customer.identityservice.auth.web.AuthErrorWriter;
import java.time.Clock;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.*;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.*;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.security.oauth2.server.resource.authentication.*;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.*;

@Configuration
public class AuthSecurityConfig {
    @Bean public Clock authClock() { return Clock.systemUTC(); }
    @Bean public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(12); }

    @Bean
    public JwtDecoder jwtDecoder(AuthSigningKeys keys,AuthRepository repository,Clock clock,
        @Value("${app.auth.issuer:library-identity}") String issuer,
        @Value("${app.auth.audience:library-api}") String audience) {
        NimbusJwtDecoder decoder=NimbusJwtDecoder.withPublicKey(keys.publicKey()).build();
        OAuth2TokenValidator<Jwt> session=jwt ->
            jwt.getAudience().contains(audience) && repository.activeSession(jwt.getClaimAsString("sid"),jwt.getSubject(),clock.instant())
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token","Session is not active",null));
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(JwtValidators.createDefaultWithIssuer(issuer),session));
        return decoder;
    }

    @Bean public AuthRateFilter authRateFilter(AuthThrottle throttle,AuthErrorWriter errors) { return new AuthRateFilter(throttle,errors); }
    @Bean public FilterRegistrationBean<AuthRateFilter> disableDuplicateRegistration(AuthRateFilter filter) {
        var registration=new FilterRegistrationBean<>(filter);registration.setEnabled(false);return registration;
    }

    @Bean
    public SecurityFilterChain authSecurity(HttpSecurity http,AuthRateFilter filter,AuthErrorWriter errors) throws Exception {
        var authorities=new JwtGrantedAuthoritiesConverter();
        authorities.setAuthoritiesClaimName("roles");authorities.setAuthorityPrefix("ROLE_");
        var converter=new JwtAuthenticationConverter();converter.setJwtGrantedAuthoritiesConverter(authorities);
        return http.csrf(AbstractHttpConfigurer::disable)
            .cors(c -> c.configurationSource(cors()))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers(HttpMethod.POST,"/api/auth/register","/api/auth/login","/api/auth/refresh").permitAll()
                .requestMatchers(HttpMethod.POST,"/api/auth/logout").authenticated()
                .requestMatchers(HttpMethod.GET,"/api/users/me").authenticated()
                .requestMatchers("/v3/api-docs/**","/swagger-ui/**","/swagger-ui.html","/error").permitAll()
                .anyRequest().denyAll())
            .oauth2ResourceServer(o -> o.jwt(j -> j.jwtAuthenticationConverter(converter))
                .authenticationEntryPoint((request,response,ex) -> errors.send(request,response,401,"SESSION_EXPIRED","Phiên đăng nhập không hợp lệ hoặc đã hết hạn.",Map.of())))
            .exceptionHandling(e -> e
                .authenticationEntryPoint((request,response,ex) -> errors.send(request,response,401,"SESSION_EXPIRED","Vui lòng đăng nhập.",Map.of()))
                .accessDeniedHandler((request,response,ex) -> errors.send(request,response,403,"FORBIDDEN","Không có quyền thực hiện thao tác.",Map.of())))
            .addFilterBefore(filter,BearerTokenAuthenticationFilter.class).build();
    }

    private CorsConfigurationSource cors() {
        var cors=new CorsConfiguration();
        cors.setAllowedOriginPatterns(java.util.List.of("http://localhost:*","http://127.0.0.1:*"));
        cors.setAllowedMethods(java.util.List.of("GET","POST","OPTIONS"));
        cors.setAllowedHeaders(java.util.List.of("Authorization","Content-Type","X-Correlation-Id"));
        cors.setExposedHeaders(java.util.List.of("Retry-After","X-Correlation-Id"));
        var source=new UrlBasedCorsConfigurationSource();source.registerCorsConfiguration("/api/**",cors);return source;
    }
}
