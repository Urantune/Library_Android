package customer.reservationservice.exception;

import customer.reservationservice.dto.response.ResponseAPI;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

@ControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(value = RuntimeException.class)
    public ResponseEntity<ResponseAPI<Object>> handleRuntimeException(RuntimeException ex) {
        log.error("Unhandled reservation service error", ex);
        return errorResponse(ErrorCode.UNCATEGORIZED_EXCEPTION,
                ErrorCode.UNCATEGORIZED_EXCEPTION.getStatusCode());
    }

    @ExceptionHandler(value = AppException.class)
    public ResponseEntity<ResponseAPI<Object>> handleAppException(AppException ex) {
        ErrorCode errorCode = ex.getErrorCode();
        return errorResponse(errorCode, errorCode.getStatusCode());
    }

    @ExceptionHandler({
            MethodArgumentNotValidException.class,
            HttpMessageNotReadableException.class,
            MissingRequestHeaderException.class
    })
    public ResponseEntity<ResponseAPI<Object>> handleBadRequest(Exception ex) {
        return errorResponse(ErrorCode.BAD_REQUEST, ErrorCode.BAD_REQUEST.getStatusCode());
    }

    private ResponseEntity<ResponseAPI<Object>> errorResponse(ErrorCode errorCode, HttpStatusCode status) {
        return ResponseEntity.status(status).body(
                ResponseAPI.builder()
                        .code(errorCode.getCode())
                        .message(errorCode.getMessage())
                        .build());
    }
}