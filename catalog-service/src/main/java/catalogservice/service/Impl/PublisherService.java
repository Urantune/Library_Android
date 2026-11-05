package catalogservice.service.Impl;

import catalogservice.dto.request.PublisherWriteRequest;
import catalogservice.dto.response.PageResponse;
import catalogservice.dto.response.PublisherResponse;
import catalogservice.entity.Publisher;
import catalogservice.repository.PublisherRepository;
import java.util.Locale;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PublisherService {
    private final PublisherRepository publishers;

    public PublisherService(PublisherRepository publishers) { this.publishers = publishers; }

    @Transactional(readOnly = true)
    public PageResponse<PublisherResponse> list(int page, int size) {
        validatePage(page, size);
        var result = publishers.findAll(PageRequest.of(page, size));
        return new PageResponse<>(result.getContent().stream().map(PublisherResponse::from).toList(),
            page, size, result.getTotalElements(), result.getTotalPages());
    }

    @Transactional(readOnly = true)
    public PublisherResponse get(String id) { return PublisherResponse.from(require(id)); }

    @Transactional
    @CacheEvict(cacheNames = "book-pages", allEntries = true)
    public PublisherResponse create(PublisherWriteRequest request) {
        String name = request.name().trim();
        if (publishers.existsByNameIgnoreCase(name)) throw conflict("Publisher name already exists");
        Publisher publisher = new Publisher();
        apply(request, publisher);
        return PublisherResponse.from(publishers.saveAndFlush(publisher));
    }

    @Transactional
    @CacheEvict(cacheNames = "book-pages", allEntries = true)
    public PublisherResponse update(String id, PublisherWriteRequest request) {
        Publisher publisher = require(id);
        String name = request.name().trim();
        if (!publisher.getName().toLowerCase(Locale.ROOT).equals(name.toLowerCase(Locale.ROOT))
            && publishers.existsByNameIgnoreCase(name)) throw conflict("Publisher name already exists");
        apply(request, publisher);
        return PublisherResponse.from(publishers.saveAndFlush(publisher));
    }

    @Transactional
    @CacheEvict(cacheNames = "book-pages", allEntries = true)
    public void delete(String id) {
        Publisher publisher = require(id);
        publisher.setStatus("INACTIVE");
        publishers.saveAndFlush(publisher);
    }

    private Publisher require(String id) {
        if (id == null || id.isBlank()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Publisher not found");
        return publishers.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Publisher not found"));
    }

    private void apply(PublisherWriteRequest request, Publisher publisher) {
        publisher.setName(request.name().trim());
        publisher.setAddress(blankToNull(request.address()));
        publisher.setEmail(blankToNull(request.email()));
        publisher.setPhone(blankToNull(request.phone()));
        publisher.setWebsite(blankToNull(request.website()));
        publisher.setStatus("ACTIVE");
    }

    private void validatePage(int page, int size) {
        if (page < 0 || size < 1 || size > 100) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid pagination");
    }

    private ResponseStatusException conflict(String message) { return new ResponseStatusException(HttpStatus.CONFLICT, message); }
    private String blankToNull(String value) { return value == null || value.isBlank() ? null : value.trim(); }
}
