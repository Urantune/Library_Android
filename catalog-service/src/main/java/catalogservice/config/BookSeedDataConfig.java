package catalogservice.config;

import catalogservice.entity.Book;
import catalogservice.enums.BookStatus;
import catalogservice.repository.BookRepository;
import java.util.List;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class BookSeedDataConfig {
    @Bean
    @ConditionalOnProperty(prefix = "app.seed", name = "books", havingValue = "true", matchIfMissing = true)
    CommandLineRunner seedBooks(BookRepository books) {
        return args -> {
            if (books.count() != 0) return;
            books.saveAll(List.of(
                book("9780132350884", "Clean Code", "Robert C. Martin's practical guide to clean software.", 2008, "en", 464),
                book("9780134685991", "Effective Java", "Best practices for the Java platform.", 2018, "en", 416),
                book("9786041149927", "Dế Mèn Phiêu Lưu Ký", "Classic Vietnamese children's literature.", 1941, "vi", 192),
                book("9780262033848", "Introduction to Algorithms", "Algorithms and data structures reference.", 2009, "en", 1312),
                book("9786043850593", "Tuổi Trẻ Đáng Giá Bao Nhiêu", "Vietnamese self-development title.", 2018, "vi", 285)
            ));
        };
    }

    private static Book book(String isbn, String title, String description, int year, String language, int pages) {
        Book book = new Book();
        book.setIsbn(isbn);
        book.setTitle(title);
        book.setDescription(description);
        book.setPublicationYear(year);
        book.setLanguage(language);
        book.setPageCount(pages);
        book.setStatus(BookStatus.ACTIVE);
        return book;
    }
}
