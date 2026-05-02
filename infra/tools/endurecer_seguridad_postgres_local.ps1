param(
    [string]$ContainerName = "fly-bd-pg-5435",
    [string]$DbUser,
    [string]$DbName,
    [string]$RuntimeRole = "fly_app_rw",
    [string]$ReadOnlyRole = "fly_app_ro",
    [string]$AuditRole = "fly_app_audit",
    [string]$DdlRole = "fly_app_ddl",
    [string]$DmlRole = "fly_app_dml"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $DbUser = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_USER)) { "fly_admin" } else { $env:POSTGRES_USER }
}

if ([string]::IsNullOrWhiteSpace($DbName)) {
    $DbName = if ([string]::IsNullOrWhiteSpace($env:POSTGRES_DB)) { "flydb" } else { $env:POSTGRES_DB }
}

function Invoke-PsqlFile {
    param(
        [string]$LocalPath,
        [string]$RemotePath
    )

    docker cp $LocalPath "${ContainerName}:$RemotePath" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo docker cp al transferir SQL de hardening."
    }

    try {
        docker exec $ContainerName psql -v ON_ERROR_STOP=1 -U $DbUser -d $DbName -f $RemotePath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Fallo psql al aplicar hardening de seguridad."
        }
    }
    finally {
        docker exec $ContainerName rm -f $RemotePath | Out-Null
    }
}

try {
    Write-Host ""
    Write-Host "======================================================"
    Write-Host "  FLY Manager - Hardening Seguridad PostgreSQL Local"
    Write-Host "======================================================"
    Write-Host ("  Contenedor: {0}" -f $ContainerName)
    Write-Host ("  Base: {0}" -f $DbName)
    Write-Host ("  Owner/Migrator actual: {0}" -f $DbUser)
    Write-Host ""

    $localSqlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("codex_pg_hardening_{0}.sql" -f [guid]::NewGuid().ToString("N"))
    $remoteSqlPath = "/tmp/{0}" -f ([System.IO.Path]::GetFileName($localSqlPath))

    $sqlTemplate = @'
DO $hardening$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{0}') THEN
    CREATE ROLE {0} NOLOGIN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{1}') THEN
    CREATE ROLE {1} NOLOGIN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{2}') THEN
    CREATE ROLE {2} NOLOGIN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{3}') THEN
    CREATE ROLE {3} NOLOGIN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{4}') THEN
    CREATE ROLE {4} NOLOGIN;
  END IF;
END
$hardening$;

REVOKE CONNECT, TEMP ON DATABASE {5} FROM PUBLIC;
GRANT CONNECT ON DATABASE {5} TO {0}, {1}, {2}, {3}, {4};
GRANT TEMP ON DATABASE {5} TO {0}, {4};

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO {0}, {1}, {2}, {3}, {4};
GRANT CREATE ON SCHEMA public TO {3};

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {0};
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO {0};

GRANT SELECT ON ALL TABLES IN SCHEMA public TO {1}, {2}, {3};
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO {1}, {2}, {3};

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {4};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {4};

ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public REVOKE ALL ON SEQUENCES FROM PUBLIC;

ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO {0};
ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO {0};

ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public
  GRANT SELECT ON TABLES TO {1}, {2}, {3};
ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO {1}, {2}, {3};

ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public
  GRANT ALL PRIVILEGES ON TABLES TO {4};
ALTER DEFAULT PRIVILEGES FOR ROLE {6} IN SCHEMA public
  GRANT ALL PRIVILEGES ON SEQUENCES TO {4};

GRANT pg_read_all_stats TO {2};

COMMENT ON ROLE {3} IS 'Rol DDL delegado: CREATE en schema public y lectura para definir vistas/funciones, sin CREATEROLE.';
COMMENT ON ROLE {4} IS 'Rol DML delegado: privilegios amplios de manipulacion de datos sin CREATEROLE.';
'@

    $sql = [string]::Format(
        $sqlTemplate,
        $RuntimeRole,
        $ReadOnlyRole,
        $AuditRole,
        $DdlRole,
        $DmlRole,
        $DbName,
        $DbUser
    )

    Set-Content -Path $localSqlPath -Value $sql -Encoding UTF8

    try {
        Invoke-PsqlFile -LocalPath $localSqlPath -RemotePath $remoteSqlPath
    }
    finally {
        if (Test-Path -LiteralPath $localSqlPath) {
            Remove-Item -LiteralPath $localSqlPath -Force
        }
    }

    Write-Host "[OK] Hardening aplicado."
    Write-Host ("[OK] Roles preparados: {0}, {1}, {2}, {3}, {4}" -f $RuntimeRole, $ReadOnlyRole, $AuditRole, $DdlRole, $DmlRole)
}
catch {
    Write-Host ""
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
