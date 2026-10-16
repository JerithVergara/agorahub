CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS agorahub;
SET search_path TO agorahub, public;

--1. Identidad, autenticación y perfiles
CREATE TABLE roles (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(30) NOT NULL UNIQUE,
    name        VARCHAR(60) NOT NULL
);

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(160) NOT NULL,
    password_hash   TEXT NOT NULL,
    full_name       VARCHAR(120) NOT NULL,
    phone           VARCHAR(30),
    avatar_url      TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'pending', 'blocked', 'deleted')),
    timezone        VARCHAR(60) NOT NULL DEFAULT 'America/Bogota',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at   TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ
);

CREATE UNIQUE INDEX uq_users_email_ci ON users (lower(email));

CREATE TABLE user_roles (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id     SMALLINT NOT NULL REFERENCES roles(id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE student_profiles (
    user_id          UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    education_level  VARCHAR(80),
    learning_goal    VARCHAR(160),
    bio              VARCHAR(500),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE tutor_profiles (
    user_id              UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    professional_title   VARCHAR(120),
    bio                  VARCHAR(1000),
    years_experience     SMALLINT CHECK (years_experience >= 0),
    hourly_rate          NUMERIC(12,2) CHECK (hourly_rate >= 0),
    currency             CHAR(3) NOT NULL DEFAULT 'COP',
    teaching_modality    VARCHAR(20) NOT NULL DEFAULT 'both'
                         CHECK (teaching_modality IN ('online', 'in_person', 'both')),
    service_area         VARCHAR(160),
    verification_status  VARCHAR(20) NOT NULL DEFAULT 'pending'
                         CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    average_rating       NUMERIC(2,1) NOT NULL DEFAULT 0
                         CHECK (average_rating BETWEEN 0 AND 5),
    review_count         INTEGER NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_sessions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at  TIMESTAMPTZ
);

CREATE INDEX ix_user_sessions_user ON user_sessions(user_id);
CREATE INDEX ix_user_sessions_expiry ON user_sessions(expires_at);

-- 2. Catálogos y perfil profesional

CREATE TABLE subjects (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE education_levels (
    id          SMALLSERIAL PRIMARY KEY,
    name        VARCHAR(80) NOT NULL UNIQUE,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE tutor_subjects (
    tutor_id        UUID NOT NULL REFERENCES tutor_profiles(user_id) ON DELETE CASCADE,
    subject_id      BIGINT NOT NULL REFERENCES subjects(id),
    hourly_rate     NUMERIC(12,2) CHECK (hourly_rate >= 0),
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (tutor_id, subject_id)
);

CREATE TABLE tutor_education_levels (
    tutor_id        UUID NOT NULL REFERENCES tutor_profiles(user_id) ON DELETE CASCADE,
    education_level_id SMALLINT NOT NULL REFERENCES education_levels(id),
    PRIMARY KEY (tutor_id, education_level_id)
);

CREATE TABLE tutor_badges (
    id          BIGSERIAL PRIMARY KEY,
    tutor_id    UUID NOT NULL REFERENCES tutor_profiles(user_id) ON DELETE CASCADE,
    name        VARCHAR(80) NOT NULL,
    description VARCHAR(255),
    awarded_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tutor_id, name)
);

CREATE TABLE verification_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id        UUID NOT NULL REFERENCES tutor_profiles(user_id) ON DELETE CASCADE,
    document_type   VARCHAR(40) NOT NULL
                    CHECK (document_type IN ('identity', 'degree', 'certificate', 'other')),
    storage_key     TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by     UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at     TIMESTAMPTZ,
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Disponibilidad y ubicación

CREATE TABLE tutor_availability_rules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id        UUID NOT NULL REFERENCES tutor_profiles(user_id) ON DELETE CASCADE,
    day_of_week     SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    modality        VARCHAR(20) NOT NULL DEFAULT 'both'
                    CHECK (modality IN ('online', 'in_person', 'both')),
    timezone        VARCHAR(60) NOT NULL DEFAULT 'America/Bogota',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (end_time > start_time)
);

CREATE INDEX ix_availability_tutor_day
    ON tutor_availability_rules(tutor_id, day_of_week, start_time);

CREATE TABLE tutor_availability_exceptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id        UUID NOT NULL REFERENCES tutor_profiles(user_id) ON DELETE CASCADE,
    starts_at       TIMESTAMPTZ NOT NULL,
    ends_at         TIMESTAMPTZ NOT NULL,
    exception_type  VARCHAR(20) NOT NULL
                    CHECK (exception_type IN ('blocked', 'extra_available')),
    reason          VARCHAR(255),
    CHECK (ends_at > starts_at)
);

CREATE TABLE user_addresses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label           VARCHAR(60),
    address_line    VARCHAR(180) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    department      VARCHAR(100),
    postal_code     VARCHAR(20),
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    is_default      BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX ix_user_addresses_city ON user_addresses(lower(city));

-- 4. Búsqueda, solicitudes y negociación

CREATE TABLE tutoring_requests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id          UUID NOT NULL REFERENCES student_profiles(user_id),
    subject_id          BIGINT NOT NULL REFERENCES subjects(id),
    education_level_id  SMALLINT REFERENCES education_levels(id),
    objective           VARCHAR(1000) NOT NULL,
    modality            VARCHAR(20) NOT NULL
                        CHECK (modality IN ('online', 'in_person')),
    preferred_starts_at TIMESTAMPTZ NOT NULL,
    preferred_ends_at   TIMESTAMPTZ,
    location_text       VARCHAR(255),
    meeting_url         TEXT,
    budget_per_hour     NUMERIC(12,2) CHECK (budget_per_hour >= 0),
    status              VARCHAR(20) NOT NULL DEFAULT 'draft'
                        CHECK (status IN ('draft', 'submitted', 'negotiating', 'accepted', 'rejected', 'cancelled', 'expired')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (preferred_ends_at IS NULL OR preferred_ends_at > preferred_starts_at),
    CHECK (modality <> 'in_person' OR location_text IS NOT NULL)
);

CREATE INDEX ix_requests_search
    ON tutoring_requests(subject_id, education_level_id, modality, status, preferred_starts_at);
CREATE INDEX ix_requests_student ON tutoring_requests(student_id, status, created_at DESC);

CREATE TABLE tutoring_proposals (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id          UUID NOT NULL REFERENCES tutoring_requests(id) ON DELETE CASCADE,
    tutor_id            UUID NOT NULL REFERENCES tutor_profiles(user_id),
    proposed_hourly_rate NUMERIC(12,2) NOT NULL CHECK (proposed_hourly_rate >= 0),
    proposed_starts_at  TIMESTAMPTZ,
    proposed_ends_at    TIMESTAMPTZ,
    message             VARCHAR(1000),
    status              VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn', 'expired')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (proposed_ends_at IS NULL OR proposed_starts_at IS NULL OR proposed_ends_at > proposed_starts_at),
    UNIQUE (request_id, tutor_id)
);

CREATE INDEX ix_proposals_tutor ON tutoring_proposals(tutor_id, status, created_at DESC);
CREATE INDEX ix_proposals_request ON tutoring_proposals(request_id, status);

CREATE TABLE negotiation_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id      UUID NOT NULL REFERENCES tutoring_requests(id) ON DELETE CASCADE,
    proposal_id     UUID REFERENCES tutoring_proposals(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(id),
    body            VARCHAR(2000) NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at         TIMESTAMPTZ
);

CREATE INDEX ix_negotiation_messages_request ON negotiation_messages(request_id, sent_at);

-- 5. Tutorías, aula virtual, archivos y notas

CREATE TABLE tutoring_sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id          UUID NOT NULL REFERENCES tutoring_requests(id),
    accepted_proposal_id UUID UNIQUE NOT NULL REFERENCES tutoring_proposals(id),
    student_id          UUID NOT NULL REFERENCES student_profiles(user_id),
    tutor_id            UUID NOT NULL REFERENCES tutor_profiles(user_id),
    subject_id          BIGINT NOT NULL REFERENCES subjects(id),
    starts_at           TIMESTAMPTZ NOT NULL,
    ends_at             TIMESTAMPTZ NOT NULL,
    modality            VARCHAR(20) NOT NULL
                        CHECK (modality IN ('online', 'in_person')),
    location_text       VARCHAR(255),
    meeting_url         TEXT,
    status              VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show')),
    cancellation_reason VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at),
    CHECK (modality <> 'in_person' OR location_text IS NOT NULL)
);

CREATE INDEX ix_sessions_student ON tutoring_sessions(student_id, starts_at DESC);
CREATE INDEX ix_sessions_tutor ON tutoring_sessions(tutor_id, starts_at DESC);
CREATE INDEX ix_sessions_status_time ON tutoring_sessions(status, starts_at);

CREATE TABLE session_files (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES tutoring_sessions(id) ON DELETE CASCADE,
    uploaded_by     UUID NOT NULL REFERENCES users(id),
    file_name       VARCHAR(255) NOT NULL,
    storage_key     TEXT NOT NULL,
    mime_type       VARCHAR(120),
    file_size_bytes BIGINT CHECK (file_size_bytes >= 0),
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE session_notes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES tutoring_sessions(id) ON DELETE CASCADE,
    author_id       UUID NOT NULL REFERENCES users(id),
    note            VARCHAR(4000) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE session_checklist_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES tutoring_sessions(id) ON DELETE CASCADE,
    label           VARCHAR(255) NOT NULL,
    is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at    TIMESTAMPTZ,
    sort_order      SMALLINT NOT NULL DEFAULT 0
);

-- 6. Reputación y reseñas

CREATE TABLE tutor_reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL UNIQUE REFERENCES tutoring_sessions(id),
    student_id      UUID NOT NULL REFERENCES student_profiles(user_id),
    tutor_id        UUID NOT NULL REFERENCES tutor_profiles(user_id),
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         VARCHAR(1000),
    is_published    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (length(trim(coalesce(comment, ''))) >= 0)
);

CREATE INDEX ix_reviews_tutor ON tutor_reviews(tutor_id, created_at DESC);

-- 7. Asistente IA

CREATE TABLE ai_conversations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES student_profiles(user_id) ON DELETE CASCADE,
    title           VARCHAR(160),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ai_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role            VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content         TEXT NOT NULL,
    model_name      VARCHAR(100),
    token_count     INTEGER CHECK (token_count >= 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_ai_messages_conversation ON ai_messages(conversation_id, created_at);

-- Datos iniciales de catálogos

INSERT INTO roles (code, name) VALUES
    ('student', 'Estudiante'),
    ('tutor', 'Tutor'),
    ('admin', 'Administrador')
ON CONFLICT (code) DO NOTHING;

INSERT INTO education_levels (name) VALUES
    ('Bachillerato'),
    ('Universidad'),
    ('Formación técnica')
ON CONFLICT (name) DO NOTHING;

INSERT INTO subjects (name) VALUES
    ('Matemáticas'),
    ('Física'),
    ('Inglés'),
    ('Programación'),
    ('Álgebra'),
    ('Cálculo')
ON CONFLICT (name) DO NOTHING;

-- Vistas de consulta para los dashboards

CREATE VIEW tutor_search_view AS
SELECT
    tp.user_id AS tutor_id,
    u.full_name,
    u.avatar_url,
    tp.professional_title,
    tp.hourly_rate,
    tp.currency,
    tp.teaching_modality,
    tp.service_area,
    tp.verification_status,
    tp.average_rating,
    tp.review_count,
    string_agg(DISTINCT s.name, ', ' ORDER BY s.name) AS subjects
FROM tutor_profiles tp
JOIN users u ON u.id = tp.user_id AND u.status = 'active'
LEFT JOIN tutor_subjects ts ON ts.tutor_id = tp.user_id
LEFT JOIN subjects s ON s.id = ts.subject_id AND s.is_active = TRUE
GROUP BY tp.user_id, u.full_name, u.avatar_url, tp.professional_title,
         tp.hourly_rate, tp.currency, tp.teaching_modality, tp.service_area,
         tp.verification_status, tp.average_rating, tp.review_count;

CREATE VIEW student_upcoming_sessions_view AS
SELECT
    ts.id AS session_id,
    ts.student_id,
    ts.tutor_id,
    tu.full_name AS tutor_name,
    s.name AS subject_name,
    ts.starts_at,
    ts.ends_at,
    ts.modality,
    ts.status,
    ts.meeting_url
FROM tutoring_sessions ts
JOIN users tu ON tu.id = ts.tutor_id
JOIN subjects s ON s.id = ts.subject_id
WHERE ts.status IN ('scheduled', 'in_progress')
  AND ts.starts_at >= now();