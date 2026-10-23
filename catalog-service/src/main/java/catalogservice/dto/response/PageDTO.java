package catalogservice.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PageDTO<T> {
    int size;
    int page;
    int totalPages;
    long totalElements;
    boolean first;
    boolean last;
    List<T> content;
}