package com.example.mulesoft.azure;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Base64;

/**
 * Azure SAS Token Generator
 * Generates short-lived Shared Access Signature tokens for Azure Blob Storage
 */
public class AzureSASTokenGenerator {

    private static final String HMAC_SHA256 = "HmacSHA256";

    /**
     * Generates a SAS token for Azure Blob Storage
     *
     * @param storageAccountName Azure storage account name
     * @param storageAccountKey Azure storage account key (base64 encoded)
     * @param containerName Container name
     * @param blobName Blob name (file name)
     * @param permissions Permissions (e.g., "racwdl" - read, add, create, write, delete, list)
     * @param expiryMinutes Token expiry time in minutes
     * @return SAS token query string
     * @throws Exception if token generation fails
     */
    public static String generateBlobSASToken(
            String storageAccountName,
            String storageAccountKey,
            String containerName,
            String blobName,
            String permissions,
            int expiryMinutes) throws Exception {

        // Calculate expiry time
        ZonedDateTime expiryTime = ZonedDateTime.now(ZoneOffset.UTC).plusMinutes(expiryMinutes);
        String expiryTimeString = expiryTime.format(DateTimeFormatter.ISO_INSTANT);

        // Start time (5 minutes before current time to account for clock skew)
        ZonedDateTime startTime = ZonedDateTime.now(ZoneOffset.UTC).minusMinutes(5);
        String startTimeString = startTime.format(DateTimeFormatter.ISO_INSTANT);

        // SAS Version
        String signedVersion = "2021-08-06";

        // Resource type (b = blob)
        String signedResource = "b";

        // Canonical resource
        String canonicalName = "/blob/" + storageAccountName + "/" + containerName + "/" + blobName;

        // String to sign
        String stringToSign = permissions + "\n" +
                startTimeString + "\n" +
                expiryTimeString + "\n" +
                canonicalName + "\n" +
                "" + "\n" + // signedIdentifier
                "" + "\n" + // signedIP
                "https" + "\n" + // signedProtocol
                signedVersion + "\n" +
                signedResource + "\n" +
                "" + "\n" + // signedSnapshotTime
                "" + "\n" + // signedEncryptionScope
                "" + "\n" + // rscc (Cache-Control)
                "" + "\n" + // rscd (Content-Disposition)
                "" + "\n" + // rsce (Content-Encoding)
                "" + "\n" + // rscl (Content-Language)
                "";          // rsct (Content-Type)

        // Generate signature
        String signature = generateSignature(storageAccountKey, stringToSign);

        // Build SAS token
        StringBuilder sasToken = new StringBuilder();
        sasToken.append("sv=").append(URLEncoder.encode(signedVersion, StandardCharsets.UTF_8.toString()));
        sasToken.append("&sr=").append(signedResource);
        sasToken.append("&sp=").append(URLEncoder.encode(permissions, StandardCharsets.UTF_8.toString()));
        sasToken.append("&st=").append(URLEncoder.encode(startTimeString, StandardCharsets.UTF_8.toString()));
        sasToken.append("&se=").append(URLEncoder.encode(expiryTimeString, StandardCharsets.UTF_8.toString()));
        sasToken.append("&spr=https");
        sasToken.append("&sig=").append(URLEncoder.encode(signature, StandardCharsets.UTF_8.toString()));

        return sasToken.toString();
    }

    /**
     * Generates a SAS token for a container (for listing blobs)
     */
    public static String generateContainerSASToken(
            String storageAccountName,
            String storageAccountKey,
            String containerName,
            String permissions,
            int expiryMinutes) throws Exception {

        ZonedDateTime expiryTime = ZonedDateTime.now(ZoneOffset.UTC).plusMinutes(expiryMinutes);
        String expiryTimeString = expiryTime.format(DateTimeFormatter.ISO_INSTANT);

        ZonedDateTime startTime = ZonedDateTime.now(ZoneOffset.UTC).minusMinutes(5);
        String startTimeString = startTime.format(DateTimeFormatter.ISO_INSTANT);

        String signedVersion = "2021-08-06";
        String signedResource = "c"; // container

        String canonicalName = "/blob/" + storageAccountName + "/" + containerName;

        String stringToSign = permissions + "\n" +
                startTimeString + "\n" +
                expiryTimeString + "\n" +
                canonicalName + "\n" +
                "" + "\n" +
                "" + "\n" +
                "https" + "\n" +
                signedVersion + "\n" +
                signedResource + "\n" +
                "" + "\n" +
                "" + "\n" +
                "" + "\n" +
                "" + "\n" +
                "" + "\n" +
                "" + "\n" +
                "";

        String signature = generateSignature(storageAccountKey, stringToSign);

        StringBuilder sasToken = new StringBuilder();
        sasToken.append("sv=").append(URLEncoder.encode(signedVersion, StandardCharsets.UTF_8.toString()));
        sasToken.append("&sr=").append(signedResource);
        sasToken.append("&sp=").append(URLEncoder.encode(permissions, StandardCharsets.UTF_8.toString()));
        sasToken.append("&st=").append(URLEncoder.encode(startTimeString, StandardCharsets.UTF_8.toString()));
        sasToken.append("&se=").append(URLEncoder.encode(expiryTimeString, StandardCharsets.UTF_8.toString()));
        sasToken.append("&spr=https");
        sasToken.append("&sig=").append(URLEncoder.encode(signature, StandardCharsets.UTF_8.toString()));

        return sasToken.toString();
    }

    /**
     * Generates HMAC-SHA256 signature
     */
    private static String generateSignature(String storageAccountKey, String stringToSign) throws Exception {
        byte[] decodedKey = Base64.getDecoder().decode(storageAccountKey);
        Mac mac = Mac.getInstance(HMAC_SHA256);
        SecretKeySpec secretKey = new SecretKeySpec(decodedKey, HMAC_SHA256);
        mac.init(secretKey);
        byte[] signature = mac.doFinal(stringToSign.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(signature);
    }

    /**
     * Builds complete blob URL with SAS token
     */
    public static String buildBlobUrlWithSAS(
            String storageAccountName,
            String containerName,
            String blobName,
            String sasToken) {

        return String.format("https://%s.blob.core.windows.net/%s/%s?%s",
                storageAccountName, containerName, blobName, sasToken);
    }
}
