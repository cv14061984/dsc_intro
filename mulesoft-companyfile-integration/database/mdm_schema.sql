-- ============================================================================
-- Informatica MDM - Company File Schema
-- Database: Oracle 19c
-- Description: Legal Entity master data table structure
-- ============================================================================

-- Create Legal Entity Table
CREATE TABLE MDM_LEGAL_ENTITY (
    LEGAL_ENTITY_ID VARCHAR2(50) PRIMARY KEY,
    LEGAL_ENTITY_NAME VARCHAR2(255) NOT NULL,
    LEGAL_ENTITY_TYPE VARCHAR2(100),
    COUNTRY VARCHAR2(2) NOT NULL,  -- ISO 3166-1 alpha-2
    COUNTRY_NAME VARCHAR2(100),

    -- Address Information
    ADDRESS_LINE1 VARCHAR2(255),
    ADDRESS_LINE2 VARCHAR2(255),
    CITY VARCHAR2(100),
    STATE VARCHAR2(100),
    POSTAL_CODE VARCHAR2(20),
    ADDRESS_COUNTRY VARCHAR2(2),

    -- Registration Information
    REGISTRATION_NUMBER VARCHAR2(50),
    TAX_ID VARCHAR2(50),

    -- Status and Dates
    STATUS VARCHAR2(20) NOT NULL CHECK (STATUS IN ('APPROVED', 'PENDING', 'REJECTED')),
    EFFECTIVE_DATE DATE,
    EXPIRY_DATE DATE,

    -- Audit Fields
    CREATED_BY VARCHAR2(100) NOT NULL,
    CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    LAST_MODIFIED_BY VARCHAR2(100),
    LAST_MODIFIED_DATE TIMESTAMP,

    -- Hierarchy
    PARENT_ENTITY VARCHAR2(50),

    -- Constraints
    CONSTRAINT FK_PARENT_ENTITY FOREIGN KEY (PARENT_ENTITY)
        REFERENCES MDM_LEGAL_ENTITY(LEGAL_ENTITY_ID)
);

-- Create Indexes for Performance
CREATE INDEX IDX_LEGAL_ENTITY_NAME ON MDM_LEGAL_ENTITY(LEGAL_ENTITY_NAME);
CREATE INDEX IDX_LEGAL_ENTITY_COUNTRY ON MDM_LEGAL_ENTITY(COUNTRY);
CREATE INDEX IDX_LEGAL_ENTITY_STATUS ON MDM_LEGAL_ENTITY(STATUS);
CREATE INDEX IDX_LEGAL_ENTITY_PARENT ON MDM_LEGAL_ENTITY(PARENT_ENTITY);
CREATE INDEX IDX_LEGAL_ENTITY_DATES ON MDM_LEGAL_ENTITY(EFFECTIVE_DATE, EXPIRY_DATE);

-- Create Composite Index for Common Queries
CREATE INDEX IDX_LEGAL_ENTITY_QUERY ON MDM_LEGAL_ENTITY(STATUS, COUNTRY, LEGAL_ENTITY_NAME);

-- Comments
COMMENT ON TABLE MDM_LEGAL_ENTITY IS 'Master data table for legal entities in Company File';
COMMENT ON COLUMN MDM_LEGAL_ENTITY.LEGAL_ENTITY_ID IS 'Unique identifier for legal entity';
COMMENT ON COLUMN MDM_LEGAL_ENTITY.STATUS IS 'Entity status: APPROVED, PENDING, or REJECTED. Only APPROVED records are exposed via APIs';
COMMENT ON COLUMN MDM_LEGAL_ENTITY.COUNTRY IS 'ISO 3166-1 alpha-2 country code';

-- ============================================================================
-- Sample Data (for testing)
-- ============================================================================

INSERT INTO MDM_LEGAL_ENTITY (
    LEGAL_ENTITY_ID, LEGAL_ENTITY_NAME, LEGAL_ENTITY_TYPE, COUNTRY, COUNTRY_NAME,
    ADDRESS_LINE1, ADDRESS_LINE2, CITY, STATE, POSTAL_CODE, ADDRESS_COUNTRY,
    REGISTRATION_NUMBER, TAX_ID, STATUS, EFFECTIVE_DATE, EXPIRY_DATE,
    CREATED_BY, CREATED_DATE, LAST_MODIFIED_BY, LAST_MODIFIED_DATE, PARENT_ENTITY
) VALUES (
    'LE001234', 'Acme Corporation Ltd', 'Corporation', 'US', 'United States',
    '123 Main Street', 'Suite 100', 'New York', 'NY', '10001', 'US',
    '12-3456789', '98-7654321', 'APPROVED', TO_DATE('2025-01-01', 'YYYY-MM-DD'),
    TO_DATE('2026-12-31', 'YYYY-MM-DD'),
    'system.user', CURRENT_TIMESTAMP, 'admin.user', CURRENT_TIMESTAMP, NULL
);

INSERT INTO MDM_LEGAL_ENTITY (
    LEGAL_ENTITY_ID, LEGAL_ENTITY_NAME, LEGAL_ENTITY_TYPE, COUNTRY, COUNTRY_NAME,
    ADDRESS_LINE1, ADDRESS_LINE2, CITY, STATE, POSTAL_CODE, ADDRESS_COUNTRY,
    REGISTRATION_NUMBER, TAX_ID, STATUS, EFFECTIVE_DATE, EXPIRY_DATE,
    CREATED_BY, CREATED_DATE, LAST_MODIFIED_BY, LAST_MODIFIED_DATE, PARENT_ENTITY
) VALUES (
    'LE001235', 'Global Finance LLC', 'LLC', 'GB', 'United Kingdom',
    '456 High Street', NULL, 'London', NULL, 'SW1A 1AA', 'GB',
    'GB123456789', 'GB987654321', 'APPROVED', TO_DATE('2024-06-15', 'YYYY-MM-DD'),
    TO_DATE('2027-06-15', 'YYYY-MM-DD'),
    'system.user', CURRENT_TIMESTAMP, 'system.user', CURRENT_TIMESTAMP, 'LE001234'
);

INSERT INTO MDM_LEGAL_ENTITY (
    LEGAL_ENTITY_ID, LEGAL_ENTITY_NAME, LEGAL_ENTITY_TYPE, COUNTRY, COUNTRY_NAME,
    ADDRESS_LINE1, ADDRESS_LINE2, CITY, STATE, POSTAL_CODE, ADDRESS_COUNTRY,
    REGISTRATION_NUMBER, TAX_ID, STATUS, EFFECTIVE_DATE, EXPIRY_DATE,
    CREATED_BY, CREATED_DATE, LAST_MODIFIED_BY, LAST_MODIFIED_DATE, PARENT_ENTITY
) VALUES (
    'LE001236', 'Pending Entity Inc', 'Corporation', 'US', 'United States',
    '789 Test Ave', NULL, 'Boston', 'MA', '02101', 'US',
    '11-2233445', '55-6677889', 'PENDING', TO_DATE('2025-11-01', 'YYYY-MM-DD'),
    NULL,
    'system.user', CURRENT_TIMESTAMP, NULL, NULL, NULL
);

-- This record won't be exposed via API (PENDING status)

COMMIT;

-- ============================================================================
-- Stored Procedures (Optional)
-- ============================================================================

-- Procedure to get approved legal entities with pagination
CREATE OR REPLACE PROCEDURE GET_APPROVED_LEGAL_ENTITIES (
    p_legal_entity_id IN VARCHAR2 DEFAULT NULL,
    p_legal_entity_name IN VARCHAR2 DEFAULT NULL,
    p_country IN VARCHAR2 DEFAULT NULL,
    p_offset IN NUMBER DEFAULT 0,
    p_limit IN NUMBER DEFAULT 100,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
        SELECT
            LEGAL_ENTITY_ID,
            LEGAL_ENTITY_NAME,
            LEGAL_ENTITY_TYPE,
            COUNTRY,
            COUNTRY_NAME,
            ADDRESS_LINE1,
            ADDRESS_LINE2,
            CITY,
            STATE,
            POSTAL_CODE,
            ADDRESS_COUNTRY,
            REGISTRATION_NUMBER,
            TAX_ID,
            STATUS,
            EFFECTIVE_DATE,
            EXPIRY_DATE,
            CREATED_BY,
            CREATED_DATE,
            LAST_MODIFIED_BY,
            LAST_MODIFIED_DATE,
            PARENT_ENTITY
        FROM MDM_LEGAL_ENTITY
        WHERE STATUS = 'APPROVED'
            AND (p_legal_entity_id IS NULL OR LEGAL_ENTITY_ID = p_legal_entity_id)
            AND (p_legal_entity_name IS NULL OR UPPER(LEGAL_ENTITY_NAME) LIKE '%' || UPPER(p_legal_entity_name) || '%')
            AND (p_country IS NULL OR COUNTRY = p_country)
        ORDER BY LEGAL_ENTITY_ID
        OFFSET p_offset ROWS
        FETCH NEXT p_limit ROWS ONLY;
END;
/

-- Procedure to get legal entity count
CREATE OR REPLACE PROCEDURE GET_APPROVED_LEGAL_ENTITIES_COUNT (
    p_legal_entity_id IN VARCHAR2 DEFAULT NULL,
    p_legal_entity_name IN VARCHAR2 DEFAULT NULL,
    p_country IN VARCHAR2 DEFAULT NULL,
    p_count OUT NUMBER
)
AS
BEGIN
    SELECT COUNT(*)
    INTO p_count
    FROM MDM_LEGAL_ENTITY
    WHERE STATUS = 'APPROVED'
        AND (p_legal_entity_id IS NULL OR LEGAL_ENTITY_ID = p_legal_entity_id)
        AND (p_legal_entity_name IS NULL OR UPPER(LEGAL_ENTITY_NAME) LIKE '%' || UPPER(p_legal_entity_name) || '%')
        AND (p_country IS NULL OR COUNTRY = p_country);
END;
/

-- ============================================================================
-- Grants (Adjust as needed for your environment)
-- ============================================================================

-- Grant permissions to MuleSoft database user
GRANT SELECT ON MDM_LEGAL_ENTITY TO MULESOFT_USER;
GRANT EXECUTE ON GET_APPROVED_LEGAL_ENTITIES TO MULESOFT_USER;
GRANT EXECUTE ON GET_APPROVED_LEGAL_ENTITIES_COUNT TO MULESOFT_USER;

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Count approved vs pending/rejected records
SELECT STATUS, COUNT(*)
FROM MDM_LEGAL_ENTITY
GROUP BY STATUS;

-- Verify approved records
SELECT LEGAL_ENTITY_ID, LEGAL_ENTITY_NAME, COUNTRY, STATUS
FROM MDM_LEGAL_ENTITY
WHERE STATUS = 'APPROVED'
ORDER BY LEGAL_ENTITY_ID;

-- Check parent-child relationships
SELECT
    child.LEGAL_ENTITY_ID AS CHILD_ID,
    child.LEGAL_ENTITY_NAME AS CHILD_NAME,
    parent.LEGAL_ENTITY_ID AS PARENT_ID,
    parent.LEGAL_ENTITY_NAME AS PARENT_NAME
FROM MDM_LEGAL_ENTITY child
LEFT JOIN MDM_LEGAL_ENTITY parent ON child.PARENT_ENTITY = parent.LEGAL_ENTITY_ID
WHERE child.PARENT_ENTITY IS NOT NULL;
