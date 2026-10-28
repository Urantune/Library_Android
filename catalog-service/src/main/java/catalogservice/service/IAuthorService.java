package catalogservice.service;

import catalogservice.dto.request.CreateAuthorRequest;
import catalogservice.dto.response.AuthorResponse;
import catalogservice.dto.response.PageDTO;

public interface IAuthorService {
    PageDTO<AuthorResponse> getAuthors(int page, int size, String name, String status);
   AuthorResponse getAuthorById (String id);
   AuthorResponse createAuthor(CreateAuthorRequest request);
    void deleteAuthor(String id);
}
