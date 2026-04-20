-- Lagos State Integrated Housing & Estate Portal (LSIHEP)
-- Database Schema - PostgreSQL 14+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_hash VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Profiles Table (PII - Encrypted)
CREATE TABLE profiles (
    profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    nin_number VARCHAR(11) ENCRYPTED,
    lasrra_id VARCHAR(50) ENCRYPTED,
    bvn_hash VARCHAR(255) ENCRYPTED,
    full_name VARCHAR(255) NOT NULL,
    dob DATE,
    lga_id INTEGER,
    employment_status VARCHAR(50),
    income_range VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Estates Table
CREATE TABLE estates (
    estate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    lga_id INTEGER NOT NULL,
    address TEXT,
    total_units INTEGER,
    amenities JSONB,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Units Table
CREATE TABLE units (
    unit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    estate_id UUID REFERENCES estates(estate_id),
    block_name VARCHAR(50),
    unit_number VARCHAR(20) NOT NULL,
    unit_type VARCHAR(20), -- 1BR, 2BR, 3BR, 4BR
    size_sqm DECIMAL(10,2),
    price_band VARCHAR(50),
    status VARCHAR(30) DEFAULT 'Available',
    amenities JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Applications Table
CREATE TABLE applications (
    app_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(profile_id),
    estate_preference_id UUID REFERENCES estates(estate_id),
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'Draft',
    merit_score INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Allocations Table
CREATE TABLE allocations (
    allocation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    app_id UUID REFERENCES applications(app_id),
    unit_id UUID REFERENCES units(unit_id),
    allocation_date TIMESTAMP,
    quota_category VARCHAR(50),
    offer_status VARCHAR(30),
    blockchain_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments Table
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID,
    transaction_ref VARCHAR(100), -- REMITA RRR
    amount_paid DECIMAL(15,2) NOT NULL,
    payment_date TIMESTAMP,
    payment_channel VARCHAR(50),
    status VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reconciliation Queue (90-Day Window)
CREATE TABLE reconciliation_queue (
    recon_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_id UUID REFERENCES payments(payment_id),
    treasury_ref VARCHAR(100),
    status VARCHAR(30) DEFAULT 'Pending',
    deadline_date DATE,
    days_remaining INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clearance Certificates
CREATE TABLE clearance_certificates (
    clearance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    allocation_id UUID REFERENCES allocations(allocation_id),
    issued_by UUID REFERENCES users(user_id),
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    certificate_ref VARCHAR(50) UNIQUE,
    blockchain_hash VARCHAR(255)
);

-- Maintenance Tickets
CREATE TABLE maintenance_tickets (
    ticket_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID REFERENCES units(unit_id),
    reported_by UUID REFERENCES users(user_id),
    category VARCHAR(50),
    urgency VARCHAR(20),
    status VARCHAR(30) DEFAULT 'Open',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit Logs (Immutable)
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    ip_address INET,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details JSONB,
    blockchain_hash VARCHAR(255)
);

-- Indexes for Performance
CREATE INDEX idx_profiles_nin ON profiles(nin_number);
CREATE INDEX idx_applications_profile_status ON applications(profile_id, status);
CREATE INDEX idx_allocations_unit_status ON allocations(unit_id, status);
CREATE INDEX idx_payments_transaction_ref ON payments(transaction_ref);
CREATE INDEX idx_reconciliation_deadline ON reconciliation_queue(deadline_date, status);
CREATE INDEX idx_maintenance_status_created ON maintenance_tickets(status, created_at);

-- Comments
COMMENT ON TABLE reconciliation_queue IS 'Tracks 90-day payment reconciliation window before allocation clearance';
COMMENT ON TABLE audit_logs IS 'Immutable audit trail - records are never deleted or updated';
