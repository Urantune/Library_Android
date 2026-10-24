package catalogservice.persistence;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.time.LocalDate;

@Converter
public class LocalDateStringConverter implements AttributeConverter<LocalDate, String> {

    @Override
    public String convertToDatabaseColumn(LocalDate value) {
        return value == null ? null : value.toString(); // yyyy-MM-dd
    }

    @Override
    public LocalDate convertToEntityAttribute(String value) {
        if (value == null || value.isBlank()) return null;
        String v = value.trim();
        return LocalDate.parse(v.length() > 10 ? v.substring(0, 10) : v);
    }
}