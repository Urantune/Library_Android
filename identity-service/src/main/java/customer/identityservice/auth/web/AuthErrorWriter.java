package customer.identityservice.auth.web;

import customer.identityservice.auth.dto.ApiResponse;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

@Component
public class AuthErrorWriter {
    private final ObjectMapper mapper;
    public AuthErrorWriter(ObjectMapper mapper) { this.mapper=mapper; }

    public static String trace(HttpServletRequest request) {
        Object existing=request.getAttribute("auth.traceId");
        if (existing!=null) return existing.toString();
        String supplied=request.getHeader("X-Correlation-Id");
        String value=supplied!=null && supplied.matches("[A-Za-z0-9._-]{1,64}") ? supplied : UUID.randomUUID().toString();
        request.setAttribute("auth.traceId",value);
        return value;
    }

    public void send(HttpServletRequest request, HttpServletResponse response, int status, String code, String message, Map<String,String> fields) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control","no-store");
        response.setHeader("X-Correlation-Id",trace(request));
        mapper.writeValue(response.getWriter(),new ApiResponse<>(status,code,message,null,fields,Instant.now(),trace(request)));
    }
}
