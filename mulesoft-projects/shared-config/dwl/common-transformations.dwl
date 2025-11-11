%dw 2.0

/**
 * Common DataWeave Transformation Functions
 * Shared across all MuleSoft APIs in the MDM-ERS Integration
 */

/**
 * Format timestamp to ISO 8601 format
 */
fun formatTimestamp(timestamp) = timestamp as String {format: "yyyy-MM-dd'T'HH:mm:ss'Z'"}

/**
 * Generate correlation ID if not provided
 */
fun getCorrelationId(headers) = headers["x-correlation-id"] default uuid()

/**
 * Build error response object
 */
fun buildErrorResponse(errorCode, errorMessage, correlationId = null) = {
    code: errorCode,
    message: errorMessage,
    correlationId: correlationId,
    timestamp: now()
}

/**
 * Build success response object
 */
fun buildSuccessResponse(message, data = null) = {
    success: true,
    message: message,
    data: data,
    timestamp: now()
}

/**
 * Mask sensitive data for logging
 */
fun maskSensitiveData(data: String, visibleChars: Number = 4) =
    if (sizeOf(data) > visibleChars)
        (data[0 to visibleChars - 1] ++ "****")
    else
        "****"

/**
 * Validate required fields
 */
fun validateRequiredFields(payload, requiredFields: Array) =
    requiredFields map (field) -> {
        field: field,
        isPresent: payload[field] != null,
        value: payload[field]
    }

/**
 * Transform MDM property to ERS format
 */
fun transformMDMToERS(mdmProperty) = {
    propertyId: mdmProperty.propertyId,
    propertyType: mdmProperty.propertyType,
    address: {
        street: mdmProperty.address.street,
        city: mdmProperty.address.city,
        state: mdmProperty.address.state,
        postalCode: mdmProperty.address.postalCode,
        country: mdmProperty.address.country
    },
    valuation: {
        currentValue: mdmProperty.valuation.currentValue,
        currency: mdmProperty.valuation.currency,
        valuationDate: mdmProperty.valuation.valuationDate
    },
    ownership: {
        ownerId: mdmProperty.ownership.ownerId,
        ownerName: mdmProperty.ownership.ownerName
    },
    status: mdmProperty.status,
    sourceSystem: "MDM"
}

/**
 * Clean null values from object
 */
fun removeNulls(obj: Object) =
    obj filterObject ((value, key) -> value != null)

/**
 * Parse date string safely
 */
fun parseDate(dateString: String | Null) =
    if (dateString != null)
        dateString as DateTime
    else
        null
