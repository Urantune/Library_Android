package customer.identityservice.auth.security;

import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.*;
import java.security.interfaces.*;
import java.security.spec.*;
import java.util.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class AuthSigningKeys {
    private final RSAPrivateKey privateKey;
    private final RSAPublicKey publicKey;

    public AuthSigningKeys(@Value("${app.auth.key-dir:./data/auth-keys}") String directory) throws Exception {
        Path dir=Path.of(directory);
        Files.createDirectories(dir);
        Path file=dir.resolve("private.pem");
        if (!Files.exists(file)) {
            KeyPairGenerator generator=KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            Files.writeString(file,pem("PRIVATE KEY",generator.generateKeyPair().getPrivate().getEncoded()),StandardOpenOption.CREATE_NEW);
            try { Files.setPosixFilePermissions(file,java.nio.file.attribute.PosixFilePermissions.fromString("rw-------")); }
            catch (UnsupportedOperationException ignored) {}
        }
        String encoded=Files.readString(file).replace("-----BEGIN PRIVATE KEY-----","").replace("-----END PRIVATE KEY-----","").replaceAll("\\s","");
        var key=(RSAPrivateCrtKey)KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(encoded)));
        privateKey=key;
        publicKey=(RSAPublicKey)KeyFactory.getInstance("RSA").generatePublic(new RSAPublicKeySpec(key.getModulus(),key.getPublicExponent()));
        Path publicFile=dir.resolve("public.pem");
        String publicPem=pem("PUBLIC KEY",publicKey.getEncoded());
        if (!Files.exists(publicFile)) Files.writeString(publicFile,publicPem,StandardOpenOption.CREATE_NEW);
        else if (!Files.readString(publicFile).replace("\r","").equals(publicPem)) throw new IllegalStateException("Auth public/private keys do not match");
    }

    private static String pem(String type, byte[] bytes) {
        return "-----BEGIN "+type+"-----\n"+Base64.getMimeEncoder(64,new byte[]{10}).encodeToString(bytes)+"\n-----END "+type+"-----\n";
    }
    public RSAPrivateKey privateKey() { return privateKey; }
    public RSAPublicKey publicKey() { return publicKey; }
}
