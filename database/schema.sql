-- ============================================================================
-- LAGOS STATE INTEGRATED HOUSING PORTAL (LSIHP)
-- PostgreSQL Database Schema — Version 1.0
-- Prepared by: PCIS — Prime Connection Integrated Solutions Ltd
-- Prepared for: Lagos State Ministry of Housing
-- Date: April 2026
-- Classification: Confidential — Government Use
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLE 1: APPLICANT
-- Stores all registered applicants and their KYC status
-- ============================================================================
CREATE TABLE applicant (
    applicant_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lasrra_id           VARCHAR(20)  UNIQUE NOT NULL,           -- Encrypted at rest
    nin                 VARCHAR(11)  UNIQUE NOT NULL,           -- Encrypted at rest
    bvn                 VARCHAR(11)  UNIQUE NOT NULL,           -- Encrypted at rest
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    middle_name         VARCHAR(100),
    date_of_birth       DATE         NOT NULL,                  -- Encrypted at rest
    gender              VARCHAR(10)  CHECK (gender IN ('Male', 'Female', 'Other')),
    email               VARCHAR(255) UNIQUE NOT NULL,           -- Encrypted at rest
    phone_primary       VARCHAR(20)  NOT NULL,
    phone_secondary     VARCHAR(20),
    employment_type     VARCHAR(30)  CHECK (employment_type IN ('Civil_Servant', 'Private', 'Self_Employed', 'Other')),
    civil_service_grade VARCHAR(10),
    mdas_code           VARCHAR(20),
    is_first_time_owner BOOLEAN      NOT NULL DEFAULT FALSE,
    kyc_status          VARCHAR(20)  NOT NULL DEFAULT 'Pending'
                                    CHECK (kyc_status IN ('Pending', 'Verified', 'Failed', 'Flagged')),
    kyc_verified_at     TIMESTAMP WITH TIME ZONE,
    blockchain_hash     VARCHAR(256),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP WITH TIME ZONE                -- Soft delete
);

-- Indexes
CREATE UNIQUE INDEX idx_applicant_lasrra   ON applicant(lasrra_id);
CREATE UNIQUE INDEX idx_applicant_nin      ON applicant(nin);
CREATE UNIQUE INDEX idx_applicant_bvn      ON applicant(bvn);
CREATE UNIQUE INDEX idx_applicant_email    ON applicant(email);
CREATE        INDEX idx_applicant_kyc      ON applicant(kyc_status);

-- ============================================================================
-- TABLE 2: HOUSING_SCHEME
-- Defines each housing scheme offered by the Ministry
-- ============================================================================
CREATE TABLE housing_scheme (
    scheme_id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_name             VARCHAR(200) NOT NULL,
    scheme_code             VARCHAR(20)  UNIQUE NOT NULL,
    scheme_type             VARCHAR(30)  NOT NULL
                                        CHECK (scheme_type IN ('Social_Housing', 'Affordable', 'Middle_Income', 'Executive')),
    location_lga            VARCHAR(100) NOT NULL,
    location_address        TEXT         NOT NULL,
    total_units             INTEGER      NOT NULL CHECK (total_units > 0),
    available_units         INTEGER      NOT NULL DEFAULT 0,
    unit_price_min          DECIMAL(15,2) NOT NULL,
    unit_price_max          DECIMAL(15,2) NOT NULL,
    eligibility_criteria    JSONB,
    allocation_open_date    DATE,
    allocation_close_date   DATE,
    scheme_status           VARCHAR(20)  NOT NULL DEFAULT 'Draft'
                                        CHECK (scheme_status IN ('Draft', 'Active', 'Closed', 'Completed')),
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_scheme_status ON housing_scheme(scheme_status);
CREATE INDEX idx_scheme_type   ON housing_scheme(scheme_type);

-- ============================================================================
-- TABLE 3: HOUSING_UNIT
-- Individual housing units within a scheme
-- ============================================================================
CREATE TABLE housing_unit (
    unit_id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_id           UUID         NOT NULL REFERENCES housing_scheme(scheme_id),
    unit_number         VARCHAR(20)  NOT NULL,
    unit_type           VARCHAR(20)  NOT NULL
                                    CHECK (unit_type IN ('Studio', '1-Bed', '2-Bed', '3-Bed', 'Duplex', 'Penthouse')),
    floor_level         INTEGER,
    floor_area_sqm      DECIMAL(8,2),
    price               DECIMAL(15,2) NOT NULL,
    status              VARCHAR(20)  NOT NULL DEFAULT 'Available'
                                    CHECK (status IN ('Available', 'Reserved', 'Allocated', 'Occupied', 'Maintenance')),
    survey_plan_ref     VARCHAR(50),
    c_of_o_ref          VARCHAR(50),
    blockchain_hash     VARCHAR(256),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(scheme_id, unit_number)
);

-- Indexes
CREATE INDEX idx_unit_scheme  ON housing_unit(scheme_id);
CREATE INDEX idx_unit_status  ON housing_unit(status);

-- ============================================================================
-- TABLE 4: APPLICATION
-- Housing applications submitted by applicants
-- ============================================================================
CREATE TABLE application (
    application_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    applicant_id        UUID         NOT NULL REFERENCES applicant(applicant_id),
    scheme_id           UUID         NOT NULL REFERENCES housing_scheme(scheme_id),
    application_ref     VARCHAR(30)  UNIQUE NOT NULL,           -- e.g. LSH-2026-00123
    status              VARCHAR(20)  NOT NULL DEFAULT 'Draft'
                                    CHECK (status IN ('Draft', 'Submitted', 'Under_Review',
                                           'Approved', 'Rejected', 'Allocated', 'Withdrawn')),
    submission_date     TIMESTAMP WITH TIME ZONE,
    merit_score         DECIMAL(5,2) CHECK (merit_score BETWEEN 0 AND 100),
    priority_band       VARCHAR(10)  CHECK (priority_band IN ('Band_A', 'Band_B', 'Band_C', 'Band_D')),
    payment_date        DATE,
    declaration_signed  BOOLEAN      NOT NULL DEFAULT FALSE,
    supporting_docs     JSONB,
    reviewer_id         UUID,
    review_notes        TEXT,
    blockchain_hash     VARCHAR(256),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP WITH TIME ZONE,
    UNIQUE(applicant_id, scheme_id)                            -- One application per scheme per applicant
);

-- Indexes
CREATE INDEX idx_application_applicant    ON application(applicant_id);
CREATE INDEX idx_application_scheme       ON application(scheme_id);
CREATE INDEX idx_application_status       ON application(status, scheme_id);
CREATE INDEX idx_application_merit_score  ON application(merit_score DESC);
CREATE INDEX idx_application_ref          ON application(application_ref);

-- ============================================================================
-- TABLE 5: PAYMENT
-- Payment transactions linked to applications
-- ============================================================================
CREATE TABLE payment (
    payment_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id      UUID         NOT NULL REFERENCES application(application_id),
    payment_ref         VARCHAR(50)  UNIQUE NOT NULL,
    payment_type        VARCHAR(30)  NOT NULL
                                    CHECK (payment_type IN ('Application_Fee', 'Initial_Deposit',
                                           'Instalment', 'Full_Payment', 'Penalty')),
    amount              DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency            CHAR(3)      NOT NULL DEFAULT 'NGN',
    payment_channel     VARCHAR(20)  NOT NULL
                                    CHECK (payment_channel IN ('Bank_Transfer', 'USSD', 'Card', 'POS', 'REMITA')),
    payment_status      VARCHAR(20)  NOT NULL DEFAULT 'Pending'
                                    CHECK (payment_status IN ('Pending', 'Confirmed', 'Failed', 'Reversed', 'Disputed')),
    treasury_confirmed  BOOLEAN      NOT NULL DEFAULT FALSE,
    confirmed_at        TIMESTAMP WITH TIME ZONE,
    workflow_triggered  BOOLEAN      NOT NULL DEFAULT FALSE,
    receipt_url         VARCHAR(500),
    blockchain_hash     VARCHAR(256),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE UNIQUE INDEX idx_payment_ref           ON payment(payment_ref);
CREATE        INDEX idx_payment_application   ON payment(application_id, payment_status);
CREATE        INDEX idx_payment_status        ON payment(payment_status);

-- ============================================================================
-- TABLE 6: ALLOCATION
-- Confirmed housing allocations
-- ============================================================================
CREATE TABLE allocation (
    allocation_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id          UUID         UNIQUE NOT NULL REFERENCES application(application_id),
    unit_id                 UUID         UNIQUE NOT NULL REFERENCES housing_unit(unit_id),
    allocated_by            VARCHAR(10)  NOT NULL CHECK (allocated_by IN ('System', 'Staff')),
    allocation_date         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    allocation_letter_ref   VARCHAR(50)  UNIQUE,
    letter_generated_at     TIMESTAMP WITH TIME ZONE,
    acceptance_status       VARCHAR(20)  NOT NULL DEFAULT 'Pending'
                                        CHECK (acceptance_status IN ('Pending', 'Accepted', 'Declined', 'Expired')),
    acceptance_deadline     DATE,
    accepted_at             TIMESTAMP WITH TIME ZONE,
    blockchain_hash         VARCHAR(256),
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE UNIQUE INDEX idx_allocation_unit        ON allocation(unit_id);
CREATE UNIQUE INDEX idx_allocation_application ON allocation(application_id);

-- ============================================================================
-- TABLE 7: DOCUMENT
-- E-Deeds, Allocation Letters, Certificates of Occupancy
-- ============================================================================
CREATE TABLE document (
    document_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id      UUID         REFERENCES application(application_id),
    allocation_id       UUID         REFERENCES allocation(allocation_id),
    document_type       VARCHAR(30)  NOT NULL
                                    CHECK (document_type IN ('Allocation_Letter', 'C_of_O',
                                           'Deed_of_Sub_Lease', 'Receipt', 'KYC_Report', 'Survey_Plan')),
    document_ref        VARCHAR(50)  UNIQUE NOT NULL,
    generated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    generated_by        VARCHAR(10)  NOT NULL CHECK (generated_by IN ('System', 'Staff')),
    storage_url         VARCHAR(500),
    digital_signature   TEXT,
    blockchain_hash     VARCHAR(256),
    status              VARCHAR(20)  NOT NULL DEFAULT 'Draft'
                                    CHECK (status IN ('Draft', 'Issued', 'Signed', 'Revoked', 'Archived')),
    issued_at           TIMESTAMP WITH TIME ZONE,
    signed_at           TIMESTAMP WITH TIME ZONE,
    expiry_date         DATE,
    deleted_at          TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_document_application ON document(application_id);
CREATE INDEX idx_document_type        ON document(document_type);
CREATE INDEX idx_document_blockchain  ON document(blockchain_hash);

-- ============================================================================
-- TABLE 8: AUDIT_LOG
-- Immutable tamper-evident log of all system actions
-- ============================================================================
CREATE TABLE audit_log (
    log_id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type         VARCHAR(50)  NOT NULL,
    entity_id           UUID         NOT NULL,
    action              VARCHAR(20)  NOT NULL
                                    CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'VIEW',
                                           'APPROVE', 'REJECT', 'ALLOCATE', 'TRIGGER')),
    performed_by        UUID,
    actor_type          VARCHAR(20)  NOT NULL
                                    CHECK (actor_type IN ('Applicant', 'Staff', 'System', 'API', 'Blockchain')),
    previous_value      JSONB,
    new_value           JSONB,
    ip_address          VARCHAR(45),
    session_id          VARCHAR(100),
    blockchain_hash     VARCHAR(256),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes (no updates/deletes on audit_log — append only)
CREATE INDEX idx_audit_entity     ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_created    ON audit_log(created_at DESC);
CREATE INDEX idx_audit_actor      ON audit_log(performed_by);
CREATE INDEX idx_audit_action     ON audit_log(action);

-- ============================================================================
-- TABLE 9: SCORING_CONFIG
-- Configurable merit scoring weights (managed by Ministry admin)
-- ============================================================================
CREATE TABLE scoring_config (
    config_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    criterion_key       VARCHAR(50)  UNIQUE NOT NULL,
    criterion_label     VARCHAR(100) NOT NULL,
    weight_percent      DECIMAL(5,2) NOT NULL,
    max_points          DECIMAL(5,2) NOT NULL,
    data_source         VARCHAR(100),
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    updated_by          UUID,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Seed default scoring config
INSERT INTO scoring_config (criterion_key, criterion_label, weight_percent, max_points, data_source) VALUES
    ('first_time_owner',    'First-time homeowner',         30.00, 30.00, 'LASRRA / Self-declaration'),
    ('civil_servant',       'Civil service status',          20.00, 20.00, 'IPPIS / MDA verification'),
    ('income_eligible',     'Income band eligibility',       20.00, 20.00, 'LIRS tax records'),
    ('payment_date',        'Payment date (earliest first)', 15.00, 15.00, 'Treasury API timestamp'),
    ('lagos_residency',     'Length of residency in Lagos',  10.00, 10.00, 'LASRRA registration date'),
    ('age_bracket',         'Age bracket (priority groups)',  5.00,  5.00, 'LASRRA date of birth');

-- ============================================================================
-- AUTO-UPDATE TRIGGER for updated_at
-- ============================================================================
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_applicant_updated
    BEFORE UPDATE ON applicant
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_application_updated
    BEFORE UPDATE ON application
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_allocation_updated
    BEFORE UPDATE ON allocation
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_unit_updated
    BEFORE UPDATE ON housing_unit
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ============================================================================
-- END OF SCHEMA
-- Version: 1.0 | April 2026
-- PCIS — www.pcis-ltd.com
-- ============================================================================
