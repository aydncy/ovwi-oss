-- =========================
-- DEVELOPERS
-- =========================

CREATE TABLE IF NOT EXISTS developers (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  jwt_secret TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- PROJECTS
-- =========================

CREATE TABLE IF NOT EXISTS projects (
  id SERIAL PRIMARY KEY,
  developer_id INT REFERENCES developers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- API KEYS IMPROVEMENT
-- =========================

ALTER TABLE api_keys
ADD COLUMN IF NOT EXISTS developer_id INT REFERENCES developers(id) ON DELETE CASCADE;

ALTER TABLE api_keys
ADD COLUMN IF NOT EXISTS project_id INT REFERENCES projects(id) ON DELETE CASCADE;

-- =========================
-- API USAGE ANALYTICS
-- =========================

CREATE TABLE IF NOT EXISTS api_usage (
  id SERIAL PRIMARY KEY,
  api_key TEXT,
  developer_id INT,
  project_id INT,
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INT NOT NULL,
  latency_ms INT NOT NULL,
  ip TEXT,
  user_agent TEXT,
  request_id TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =========================
-- PERFORMANCE INDEXES
-- =========================

CREATE INDEX IF NOT EXISTS idx_api_usage_api_key
ON api_usage(api_key);

CREATE INDEX IF NOT EXISTS idx_api_usage_developer
ON api_usage(developer_id);

CREATE INDEX IF NOT EXISTS idx_api_usage_project
ON api_usage(project_id);

CREATE INDEX IF NOT EXISTS idx_api_usage_endpoint
ON api_usage(endpoint);

CREATE INDEX IF NOT EXISTS idx_api_usage_status
ON api_usage(status_code);

CREATE INDEX IF NOT EXISTS idx_api_usage_created
ON api_usage(created_at);

CREATE INDEX IF NOT EXISTS idx_developers_email
ON developers(email);

CREATE INDEX IF NOT EXISTS idx_api_keys_developer
ON api_keys(developer_id);

-- =========================
-- CLINICFLOW CORE TABLES
-- =========================

CREATE TABLE IF NOT EXISTS clinics (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctors (
  id SERIAL PRIMARY KEY,
  clinic_id INT REFERENCES clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  specialty TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS patients (
  id SERIAL PRIMARY KEY,
  clinic_id INT REFERENCES clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  birth_date DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS appointments (
  id SERIAL PRIMARY KEY,
  clinic_id INT REFERENCES clinics(id) ON DELETE CASCADE,
  doctor_id INT REFERENCES doctors(id),
  patient_id INT REFERENCES patients(id),
  appointment_time TIMESTAMP,
  status TEXT DEFAULT 'scheduled',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_appointments_clinic
ON appointments(clinic_id);

CREATE INDEX IF NOT EXISTS idx_appointments_time
ON appointments(appointment_time);

