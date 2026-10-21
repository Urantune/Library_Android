package customer.catalogservice.book;

import customer.catalogservice.entity.Book;
import customer.catalogservice.entity.BookStatus;
import customer.catalogservice.repository.BookRepository;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {"eureka.client.enabled=false", "spring.cloud.discovery.enabled=false"})
class BookReadIntegrationTest {
    private static final String DB = "jdbc:sqlite:target/books-" + UUID.randomUUID() + ".db";
    private static final String ID = "9a3019b0-786b-4000-8000-000000000001";
    @Autowired WebApplicationContext context;
    @Autowired JdbcTemplate jdbc;
    @Autowired BookRepository books;
    private MockMvc mvc;

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> DB);
    }

    @BeforeEach
    void prepare() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
        for (String table : new String[]{"book_authors", "book_categories", "book_copies", "books", "authors", "categories", "publishers"}) {
            jdbc.update("DELETE FROM " + table);
        }
        jdbc.update("INSERT INTO publishers(id,name,status,created_at,updated_at) VALUES('publisher-1','NXB','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
        jdbc.update("INSERT INTO authors(id,name,bio,country,status,created_at,updated_at) VALUES('author-1','Robert Martin','Author bio','US','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
        jdbc.update("INSERT INTO categories(id,name,status,created_at,updated_at) VALUES('category-1','Technology','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
        jdbc.update("INSERT INTO books(id,isbn,title,publisher_id,status,publication_year,page_count,created_at,updated_at) VALUES(?, '9780132350884','Clean Code','publisher-1','ACTIVE',2008,464,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)", ID);
        jdbc.update("INSERT INTO books(id,isbn,title,status,created_at,updated_at) VALUES('inactive-1','0002','Archived','INACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
        jdbc.update("INSERT INTO books(id,isbn,title,status,created_at,updated_at) VALUES('active-2','0003','Effective Java','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
        jdbc.update("INSERT INTO book_authors(book_id,author_id) VALUES(?,'author-1')", ID);
        jdbc.update("INSERT INTO book_categories(book_id,category_id) VALUES(?,'category-1')", ID);
        jdbc.update("INSERT INTO book_copies(id,book_id,accession_code,condition,circulation_status,created_at,updated_at) VALUES('copy-1',?,'ACC-1','GOOD','AVAILABLE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)", ID);
        jdbc.update("INSERT INTO book_copies(id,book_id,accession_code,condition,circulation_status,created_at,updated_at) VALUES('copy-2',?,'ACC-2','GOOD','BORROWED',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)", ID);
    }

    @Test
    void listsOnlyActiveBooksWithStablePagination() throws Exception {
        mvc.perform(get("/api/books").param("size", "1").header("X-Correlation-Id", "books-test"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.traceId").value("books-test"))
            .andExpect(jsonPath("$.data.totalElements").value(2))
            .andExpect(jsonPath("$.data.totalPages").value(2))
            .andExpect(jsonPath("$.data.items[0].id").value(ID));
        mvc.perform(get("/api/books").param("page", "1").param("size", "1"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.items[0].title").value("Effective Java"));
        mvc.perform(get("/api/books").param("page", "10"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.items").isEmpty());
    }

    @Test
    void detailMapsRelationsAndCountsPhysicalCopies() throws Exception {
        mvc.perform(get("/api/books/" + ID))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.publisher.name").value("NXB"))
            .andExpect(jsonPath("$.data.authors[0].name").value("Robert Martin"))
            .andExpect(jsonPath("$.data.categories[0].name").value("Technology"))
            .andExpect(jsonPath("$.data.pageCount").value(464))
            .andExpect(jsonPath("$.data.totalCopies").value(2))
            .andExpect(jsonPath("$.data.availableCopies").value(1));
    }

    @Test
    void missingBookReturnsStructured404() throws Exception {
        mvc.perform(get("/api/books/missing").header("X-Correlation-Id", "missing-test"))
            .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("BOOK_NOT_FOUND"))
            .andExpect(jsonPath("$.traceId").value("missing-test"));
    }

    @Test
    void rejectsInvalidPaginationAndParameterTypes() throws Exception {
        for (String[] query : new String[][]{{"page", "-1"}, {"size", "0"}, {"size", "101"}, {"page", "abc"}}) {
            mvc.perform(get("/api/books").param(query[0], query[1]))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.status").value(400));
        }
    }

    @Test
    void persistsGeneratedUuidWithMigratedSqliteSchema() {
        Book book = new Book();
        book.setTitle("New book");
        book.setIsbn("9780134685991");
        book.setStatus(BookStatus.ACTIVE);
        book.setPageCount(100);
        Book saved = books.saveAndFlush(book);
        assertThat(UUID.fromString(saved.getId())).isNotNull();
        assertThat(books.findById(saved.getId())).isPresent();
    }

    private static final String INPUT = """
        {"title":"A new book","isbn":"978-0000000009","publicationYear":2024,
         "pageCount":120,"publisherId":"publisher-1","authorIds":["author-1"],
         "categoryIds":["category-1"],"status":"ACTIVE"}
        """;

    @Test
    void createsBookAndReturnsGeneratedIdLocationAndRelations() throws Exception {
        mvc.perform(post("/api/books").contentType("application/json").content(INPUT))
            .andExpect(status().isCreated()).andExpect(header().exists("Location"))
            .andExpect(jsonPath("$.status").value(201))
            .andExpect(jsonPath("$.data.isbn").value("9780000000009"))
            .andExpect(jsonPath("$.data.authors[0].id").value("author-1"))
            .andExpect(jsonPath("$.data.totalCopies").value(0));
        assertThat(books.findByIsbn("9780000000009")).isPresent();
    }

    @Test
    void updatesBookAndReplacesRelationshipsWithoutCreatingCopies() throws Exception {
        String input = INPUT.replace("978-0000000009", "9780132350884")
            .replace("\"author-1\"", "").replace("\"category-1\"", "");
        mvc.perform(put("/api/books/" + ID).contentType("application/json").content(input))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.title").value("A new book"))
            .andExpect(jsonPath("$.data.authors").isEmpty())
            .andExpect(jsonPath("$.data.categories").isEmpty())
            .andExpect(jsonPath("$.data.totalCopies").value(2));
        mvc.perform(get("/api/books/" + ID))
            .andExpect(jsonPath("$.data.title").value("A new book"));
    }

    @Test
    void duplicateIsbnIsRejectedOnCreateAndUpdate() throws Exception {
        String duplicate = INPUT.replace("978-0000000009", "9780132350884");
        mvc.perform(post("/api/books").contentType("application/json").content(duplicate))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("DUPLICATE_ISBN"));
        mvc.perform(put("/api/books/active-2").contentType("application/json").content(duplicate))
            .andExpect(status().isConflict());
        assertThat(books.findById("active-2").orElseThrow().getIsbn()).isEqualTo("0003");
    }

    @Test
    void invalidInputAndReferencesDoNotPartiallySave() throws Exception {
        for (String invalid : new String[]{
            INPUT.replace("A new book", " "), INPUT.replace("120", "-1"),
            INPUT.replace("2024", "9999"), INPUT.replace("ACTIVE", "UNKNOWN"),
            INPUT.replace("author-1", "missing"), INPUT.replace("category-1", "missing"),
            INPUT.replace("publisher-1", "missing"), "{broken"
        }) {
            mvc.perform(post("/api/books").contentType("application/json").content(invalid))
                .andExpect(status().isBadRequest());
        }
        assertThat(books.findByIsbn("9780000000009")).isEmpty();
        mvc.perform(put("/api/books/" + ID).contentType("application/json")
            .content(INPUT.replace("author-1", "missing")))
            .andExpect(status().isBadRequest());
        assertThat(books.findById(ID).orElseThrow().getTitle()).isEqualTo("Clean Code");
    }

    @Test
    void softDeleteKeepsCopiesAndHistoricalDetailAndIsIdempotent() throws Exception {
        mvc.perform(delete("/api/books/" + ID)).andExpect(status().isNoContent());
        mvc.perform(delete("/api/books/" + ID)).andExpect(status().isNoContent());
        mvc.perform(get("/api/books")).andExpect(jsonPath("$.data.totalElements").value(1));
        mvc.perform(get("/api/books/" + ID)).andExpect(status().isOk())
            .andExpect(jsonPath("$.data.status").value("INACTIVE"))
            .andExpect(jsonPath("$.data.totalCopies").value(2));
    }

    @Test
    void unknownUpdateAndDeleteReturn404() throws Exception {
        mvc.perform(put("/api/books/missing").contentType("application/json").content(INPUT))
            .andExpect(status().isNotFound());
        mvc.perform(delete("/api/books/missing")).andExpect(status().isNotFound());
    }
}
