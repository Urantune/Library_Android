package catalogservice.mapper;


import catalogservice.dto.response.AuthorResponse;
import catalogservice.entity.Author;
import org.mapstruct.Mapping;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface AuthorMapper {
   @Mapping(target = "id",source = "id")
   @Mapping(target = "created_at", source = "createdAt")
   @Mapping(target = "updated_at", source = "updatedAt")
   AuthorResponse toAuthor(Author author);
}
