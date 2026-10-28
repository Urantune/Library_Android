package customer.identityservice.auth.web;

import customer.identityservice.auth.dto.ApiResponse;
import customer.identityservice.auth.service.AuthException;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.*;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

@RestControllerAdvice(assignableTypes=AuthController.class)
public class AuthExceptionHandler {
    @ExceptionHandler(AuthException.class)
    public ResponseEntity<ApiResponse<Void>> expected(AuthException ex,HttpServletRequest request) {
        var result=ResponseEntity.status(ex.status);
        if(ex.retryAfter>0) result.header("Retry-After",Long.toString(ex.retryAfter));
        return result.body(error(ex.status,ex.code,ex.getMessage(),ex.fields,request));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> validation(MethodArgumentNotValidException ex,HttpServletRequest request) {
        Map<String,String> fields=new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(e -> fields.putIfAbsent(e.getField(),switch(e.getField()){
            case "email" -> "Email không hợp lệ.";
            case "password" -> "Mật khẩu cần 8–72 ký tự khi đăng ký.";
            case "fullName" -> "Họ tên cần 2–100 ký tự.";
            default -> "Dữ liệu không hợp lệ.";
        }));
        return ResponseEntity.badRequest().body(error(400,"INVALID_INPUT","Vui lòng kiểm tra thông tin.",fields,request));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> invalidBody(HttpServletRequest request) {
        return ResponseEntity.badRequest().body(error(400,"INVALID_JSON","Dữ liệu gửi lên không hợp lệ.",Map.of(),request));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Void>> conflict(HttpServletRequest request) {
        return ResponseEntity.status(409).body(error(409,"ACCOUNT_CONFLICT","Thông tin tài khoản đã tồn tại.",Map.of(),request));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> unexpected(Exception ex,HttpServletRequest request) {
        LoggerFactory.getLogger(getClass()).error("Auth request failed: trace={} type={}",AuthErrorWriter.trace(request),ex.getClass().getSimpleName());
        return ResponseEntity.internalServerError().body(error(500,"INTERNAL_ERROR","Không thể xử lý lúc này. Vui lòng thử lại sau.",Map.of(),request));
    }

    private ApiResponse<Void> error(int status,String code,String message,Map<String,String> fields,HttpServletRequest request) {
        return new ApiResponse<>(status,code,message,null,fields,Instant.now(),AuthErrorWriter.trace(request));
    }
}
