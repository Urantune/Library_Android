package catalogservice.service.Impl;

import catalogservice.dto.request.CreateAuthorRequest;
import catalogservice.dto.response.AuthorResponse;
import catalogservice.dto.response.PageDTO;
import catalogservice.dto.response.ResponseAPI;
import catalogservice.entity.Author;
import catalogservice.exception.AppException;
import catalogservice.exception.ErrorCode;
import catalogservice.mapper.AuthorMapper;
import catalogservice.repository.AuthorRepository;
import catalogservice.service.IAuthorService;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
public class AuthorService implements IAuthorService {
    AuthorRepository authorRepository;
    AuthorMapper authorMapper;

    @Override
    public PageDTO<AuthorResponse> getAuthors(
            int page, int size, String name, String status) {

        // Validate pagination
        if (size > 100) {
            size = 100;
        }
        if (size < 1) {
            size = 10;
        }
        if (page < 0) {
            page = 0;
        }

        Pageable pageable = PageRequest.of(page, size);

        Page<Author> authorPage = authorRepository.searchAuthors(name, status, pageable);
        List<AuthorResponse> authorResponses =
                authorPage.getContent()
                        .stream()
                        .map(authorMapper::toAuthor)
                        .toList();
        return PageDTO.<AuthorResponse>builder()
                .content(authorResponses)
                .page(authorPage.getNumber())
                .size(authorPage.getSize())
                .totalElements(authorPage.getTotalElements())
                .totalPages(authorPage.getTotalPages())
                .first(authorPage.isFirst())
                .last(authorPage.isLast())
                .build();
    }

    @Override
    public AuthorResponse getAuthorById(String id) {
        Author author = authorRepository.findById(id).orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));
        return authorMapper.toAuthor(author);
    }

    @Override
    public AuthorResponse createAuthor(CreateAuthorRequest request) {
        if (authorRepository.existsByName(request.getName())) {
            throw new AppException(ErrorCode.AUTHOR_EXISTED);
        }
        Author author = authorMapper.createAuthor(request);
        author.setId("AUT" + UUID.randomUUID().toString().replace("-", "").substring(0, 12));
        author = authorRepository.save(author);
        return authorMapper.toAuthor(author);
    }

    @Override
    public void deleteAuthor(String id) {
        Author author = authorRepository.findById(id).orElseThrow(() -> new AppException(ErrorCode.NOT_FOUND));
        authorRepository.delete(author);
    }
}
