package catalogservice.service;

import catalogservice.dto.request.CreateAuthorRequest;
import catalogservice.dto.request.UpdateAuthor;
import catalogservice.dto.response.AuthorResponse;
import catalogservice.dto.response.PageDTO;
import catalogservice.dto.response.ResponseAPI;

public interface IAuthorService {
    PageDTO<AuthorResponse> getAuthors(int page, int size, String name, String status);
   AuthorResponse getAuthorById (String id);
   AuthorResponse createAuthor(CreateAuthorRequest request);
   AuthorResponse updateAuthor(String id, UpdateAuthor request);
    void deleteAuthor(String id);
}
