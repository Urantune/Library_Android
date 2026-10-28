package customer.identityservice.auth.security;

import customer.identityservice.auth.service.*;
import customer.identityservice.auth.web.AuthErrorWriter;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;
import java.util.Map;
import org.springframework.web.filter.OncePerRequestFilter;

public class AuthRateFilter extends OncePerRequestFilter {
    private final AuthThrottle throttle;
    private final AuthErrorWriter errors;
    public AuthRateFilter(AuthThrottle throttle,AuthErrorWriter errors) { this.throttle=throttle;this.errors=errors; }

    @Override
    protected void doFilterInternal(HttpServletRequest request,HttpServletResponse response,FilterChain chain) throws ServletException,IOException {
        response.setHeader("X-Correlation-Id",AuthErrorWriter.trace(request));
        response.setHeader("Cache-Control","no-store");
        String path=request.getRequestURI().substring(request.getContextPath().length());
        if (!"POST".equals(request.getMethod()) || !path.startsWith("/api/auth/")) {
            chain.doFilter(request,response);
            return;
        }
        try {
            String operation=path.substring("/api/auth/".length());
            if (java.util.Set.of("login","register","refresh","logout").contains(operation)) {
                int limit="register".equals(operation)?5:("login".equals(operation)?30:60);
                throttle.consume("ip:"+operation+":"+AuthThrottle.hash(request.getRemoteAddr()),limit,"register".equals(operation)?3600:60);
            }
            byte[] body=request.getInputStream().readNBytes(8193);
            if(body.length>8192) {
                errors.send(request,response,413,"PAYLOAD_TOO_LARGE","Yêu cầu vượt quá dung lượng cho phép.",Map.of());
                return;
            }
            chain.doFilter(new HttpServletRequestWrapper(request) {
                @Override public ServletInputStream getInputStream() {
                    ByteArrayInputStream input=new ByteArrayInputStream(body);
                    return new ServletInputStream() {
                        @Override public int read() { return input.read(); }
                        @Override public boolean isFinished() { return input.available()==0; }
                        @Override public boolean isReady() { return true; }
                        @Override public void setReadListener(ReadListener listener) { throw new IllegalStateException("Async body reads are not supported"); }
                    };
                }
                @Override public BufferedReader getReader() { return new BufferedReader(new InputStreamReader(getInputStream(),java.nio.charset.StandardCharsets.UTF_8)); }
            },response);
        } catch(AuthException ex) {
            if(ex.retryAfter>0)response.setHeader("Retry-After",Long.toString(ex.retryAfter));
            errors.send(request,response,ex.status,ex.code,ex.getMessage(),ex.fields);
        }
    }
}
