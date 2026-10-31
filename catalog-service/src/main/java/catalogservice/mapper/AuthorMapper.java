package catalogservice.mapper;


import catalogservice.dto.request.CreateAuthorRequest;
import catalogservice.dto.request.UpdateAuthor;
import catalogservice.dto.response.AuthorResponse;
import catalogservice.entity.Author;
import org.mapstruct.*;

@Mapper(componentModel = "spring")
public interface AuthorMapper {

   @Mapping(target = "id", ignore = true)
   Author createAuthor(CreateAuthorRequest request);

   @Mapping(target = "id",source = "id")
   @Mapping(target = "created_at", source = "createdAt")
   @Mapping(target = "updated_at", source = "updatedAt")
   AuthorResponse toAuthor(Author author);

   @Mapping(target = "id", ignore = true)
   @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
   void updateAuthor(UpdateAuthor request, @MappingTarget Author entity);
}
