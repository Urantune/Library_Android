package catalogservice.controller;

import catalogservice.dto.response.AuthorResponse;
import catalogservice.dto.response.PageDTO;
import catalogservice.dto.response.ResponseAPI;
import catalogservice.service.IAuthorService;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.temporal.ChronoUnit;


@FieldDefaults(level = lombok.AccessLevel.PRIVATE,makeFinal = true)
@RequiredArgsConstructor
@RequestMapping("/api/authors")
@RestController
public class AuthorController {
    IAuthorService authorService;
    String timestamp() {return Instant.now().truncatedTo(ChronoUnit.SECONDS).toString();}

    @GetMapping
    public ResponseEntity<ResponseAPI<PageDTO<AuthorResponse>>> getAuthors(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String status) {

        PageDTO<AuthorResponse> pageDTO = authorService.getAuthors(page, size, name, status);
        ResponseAPI<PageDTO<AuthorResponse>> response =
                ResponseAPI.<PageDTO<AuthorResponse>>builder()
                        .message("Authors retrieved successfully")
                        .result(pageDTO)
                        .timestamp(timestamp())
                        .build();

        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseAPI<AuthorResponse>> getAuthorById(@PathVariable String id) {
        ResponseAPI<AuthorResponse> response =
                ResponseAPI.<AuthorResponse>builder()
                        .message("Department retrieved successfully")
                        .result(authorService.getAuthorById(id))
                        .timestamp(timestamp())
                        .build();
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }
}
