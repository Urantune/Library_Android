package customer.identityservice.auth;

import customer.identityservice.auth.service.AuthThrottle;
import jakarta.servlet.Filter;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.*;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import tools.jackson.databind.ObjectMapper;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={"eureka.client.enabled=false","spring.cloud.discovery.enabled=false"})
class AuthIntegrationTest {
    private static final String RUN=UUID.randomUUID().toString();
    @DynamicPropertySource static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url",()->"jdbc:sqlite:target/auth-"+RUN+".db");
        registry.add("app.auth.key-dir",()->"target/auth-keys-"+RUN);
    }
    @Autowired WebApplicationContext context;
    @Autowired @Qualifier("springSecurityFilterChain") Filter security;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @Autowired PasswordEncoder passwords;
    MockMvc mvc;
    static final String PASSWORD="SafePassword123!";

    @BeforeEach void prepare() {
        mvc=MockMvcBuilders.webAppContextSetup(context).addFilters(security).build();
        for(String table:List.of("refresh_tokens","auth_sessions","user_roles","auth_audit_logs","users","auth_throttle")) jdbc.update("DELETE FROM "+table);
    }

    private String registerBody(String email) throws Exception {
        return json.writeValueAsString(Map.of("email",email,"password",PASSWORD,"fullName","Dương Phúc Khang","roles",List.of("ADMIN")));
    }
    private void register() throws Exception {
        mvc.perform(post("/api/auth/register").contentType("application/json").content(registerBody("khang@example.com")))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.data.roles[0]").value("MEMBER"));
    }
    private Map<String,Object> login() throws Exception {
        String body=json.writeValueAsString(Map.of("email","KHANG@example.com","password",PASSWORD));
        var response=mvc.perform(post("/api/auth/login").contentType("application/json").content(body))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.accessToken").isString())
            .andReturn().getResponse().getContentAsString();
        return (Map<String,Object>)json.readValue(response,Map.class).get("data");
    }

    @Test void registersWithHashedPasswordAndNeverAcceptsClientRoles() throws Exception {
        register();
        String hash=jdbc.queryForObject("SELECT password_hash FROM users",String.class);
        assertThat(hash).isNotEqualTo(PASSWORD);
        assertThat(passwords.matches(PASSWORD,hash)).isTrue();
        assertThat(jdbc.queryForObject("SELECT email FROM users",String.class)).isEqualTo("khang@example.com");
        mvc.perform(post("/api/auth/register").contentType("application/json").content(registerBody("KHANG@example.com")))
            .andExpect(status().isConflict());
    }

    @Test void loginRestoresProfileAndLogoutRevokesBothTokensImmediately() throws Exception {
        register();var session=login();String access=session.get("accessToken").toString();
        mvc.perform(get("/api/users/me").header("Authorization","Bearer "+access))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.email").value("khang@example.com"));
        mvc.perform(post("/api/auth/logout").header("Authorization","Bearer "+access)).andExpect(status().isNoContent());
        mvc.perform(get("/api/users/me").header("Authorization","Bearer "+access)).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType("application/json").content(json.writeValueAsString(Map.of("refreshToken",session.get("refreshToken")))))
            .andExpect(status().isUnauthorized());
    }

    @Test void refreshRotatesHashedTokensAndReuseRevokesSessionFamily() throws Exception {
        register();var session=login();String raw=session.get("refreshToken").toString();
        String hash=jdbc.queryForObject("SELECT token_hash FROM refresh_tokens",String.class);
        assertThat(hash).isEqualTo(AuthThrottle.hash(raw)).isNotEqualTo(raw);
        var result=mvc.perform(post("/api/auth/refresh").contentType("application/json").content(json.writeValueAsString(Map.of("refreshToken",raw))))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        var renewed=(Map<String,Object>)json.readValue(result,Map.class).get("data");
        assertThat(renewed.get("refreshToken")).isNotEqualTo(raw);
        mvc.perform(post("/api/auth/refresh").contentType("application/json").content(json.writeValueAsString(Map.of("refreshToken",raw))))
            .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/users/me").header("Authorization","Bearer "+renewed.get("accessToken")))
            .andExpect(status().isUnauthorized());
    }

    @Test void wrongAndMissingAccountsHaveTheSameErrorAndAreThrottled() throws Exception {
        register();
        for(String email:List.of("khang@example.com","missing@example.com")) {
            for(int i=0;i<5;i++) mvc.perform(post("/api/auth/login").contentType("application/json")
                .content(json.writeValueAsString(Map.of("email",email,"password","incorrect"))))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
            mvc.perform(post("/api/auth/login").contentType("application/json")
                .content(json.writeValueAsString(Map.of("email",email,"password",PASSWORD))))
                .andExpect(status().isTooManyRequests()).andExpect(header().exists("Retry-After"));
        }
    }

    @Test void ipThrottlingCannotBeBypassedWithForwardedHeaderAndRecoversAfterWindow() throws Exception {
        for(int i=0;i<30;i++) mvc.perform(post("/api/auth/login").header("X-Forwarded-For","spoof-"+i)
            .contentType("application/json").content("{}" )).andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/login").contentType("application/json").content("{}"))
            .andExpect(status().isTooManyRequests());
        jdbc.update("UPDATE auth_throttle SET ends_at=0");
        mvc.perform(post("/api/auth/login").contentType("application/json").content("{}"))
            .andExpect(status().isBadRequest());
    }

    @Test void registerSpamIsBoundedByIp() throws Exception {
        for(int i=0;i<5;i++) mvc.perform(post("/api/auth/register").contentType("application/json").content("{}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/register").contentType("application/json").content("{}"))
            .andExpect(status().isTooManyRequests());
    }

    @Test void lockedExpiredAndForgedSessionsCannotAccessProfile() throws Exception {
        register();var session=login();String access=session.get("accessToken").toString();
        mvc.perform(get("/api/users/me")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/users/me").header("Authorization","Bearer "+access+"tampered"))
            .andExpect(status().isUnauthorized());
        jdbc.update("UPDATE users SET status='LOCKED'");
        mvc.perform(get("/api/users/me").header("Authorization","Bearer "+access)).andExpect(status().isUnauthorized());
        jdbc.update("UPDATE users SET status='ACTIVE'");
        jdbc.update("UPDATE auth_sessions SET expires_at='2000-01-01T00:00:00Z'");
        mvc.perform(get("/api/users/me").header("Authorization","Bearer "+access)).andExpect(status().isUnauthorized());
    }

    @Test void invalidInputOversizedBodiesAndSqlPayloadDoNotCreateAccounts() throws Exception {
        mvc.perform(post("/api/auth/register").contentType("application/json")
            .content("{\"email\":\"bad\",\"password\":\"1\",\"fullName\":\" \"}"))
            .andExpect(status().isBadRequest()).andExpect(jsonPath("$.fieldErrors.email").exists());
        mvc.perform(post("/api/auth/login").contentType("application/json").content("x".repeat(9000)))
            .andExpect(status().isPayloadTooLarge());
        mvc.perform(post("/api/auth/login").contentType("application/json").content("{broken"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/login").contentType("application/json")
            .content(json.writeValueAsString(Map.of("email","x'OR'1'='1@example.com","password",PASSWORD))))
            .andExpect(result -> assertThat(result.getResponse().getStatus()).isIn(400,401));
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM users",Integer.class)).isZero();
    }
}
