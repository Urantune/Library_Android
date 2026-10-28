package catalogservice.controller;

import catalogservice.dto.request.CreateAuthorRequest;
import catalogservice.dto.response.AuthorResponse;
import catalogservice.dto.response.PageDTO;
import catalogservice.dto.response.ResponseAPI;
import catalogservice.service.IAuthorService;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
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

    @PostMapping
    public ResponseEntity<ResponseAPI<AuthorResponse>> createAuthor(@RequestBody CreateAuthorRequest request) {
        ResponseAPI<AuthorResponse> response =
                ResponseAPI.<AuthorResponse>builder()
                        .message("Author created successfully.")
                        .result(authorService.createAuthor(request))
                        .timestamp(timestamp())
                        .build();
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

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
                        .message("Author retrieved successfully")
                        .result(authorService.getAuthorById(id))
                        .timestamp(timestamp())
                        .build();
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseAPI<Void>> deleteCar(@PathVariable String id){
        authorService.deleteAuthor(id);
        ResponseAPI<Void> response = ResponseAPI.<Void>builder()
                .message("Author deleted successfully.")
                .timestamp(timestamp())
                .build();
        return ResponseEntity.ok(response);
    }
}
