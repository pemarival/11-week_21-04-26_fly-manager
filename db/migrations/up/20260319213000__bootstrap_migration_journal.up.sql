-- MIGRATION: 20260319213000
-- NAME: bootstrap_migration_journal
-- ROLLBACK: reversible
-- AUTHOR: codex

BEGIN;

CREATE TABLE IF NOT EXISTS public.schema_migration_journal (
    migration_id     char(14) PRIMARY KEY,
    migration_name   text NOT NULL,
    checksum_sha256  char(64) NOT NULL,
    script_path      text NOT NULL,
    rollback_mode    text NOT NULL,
    execution_ms     integer NOT NULL DEFAULT 0,
    executed_by      text NOT NULL DEFAULT current_user,
    executed_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_schema_migration_journal_executed_at
    ON public.schema_migration_journal (executed_at DESC);

COMMENT ON TABLE public.schema_migration_journal IS
    'Bitacora operativa de migraciones versionadas aplicadas sobre el release congelado.';

COMMIT;
