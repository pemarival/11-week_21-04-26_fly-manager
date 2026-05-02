-- MIGRATION: 20260319213000
-- NAME: bootstrap_migration_journal
-- ROLLBACK: reversible
-- AUTHOR: codex

BEGIN;

DROP TABLE IF EXISTS public.schema_migration_journal;

COMMIT;
