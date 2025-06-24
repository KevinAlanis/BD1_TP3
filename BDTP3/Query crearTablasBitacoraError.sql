USE BDTP31;
GO

-- ========================================
-- Tabla: BitacoraEvento
-- ========================================
CREATE TABLE dbo.BitacoraEvento (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL FOREIGN KEY REFERENCES dbo.Usuario(Id),
    IdTipoEvento INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoEvento(Id),
    FechaHora DATETIME NOT NULL DEFAULT GETDATE(),
    IP NVARCHAR(50) NULL,
    Parametros NVARCHAR(MAX) NULL,         -- JSON con parámetros recibidos
    Antes NVARCHAR(MAX) NULL,              -- JSON con estado antes de cambio
    Despues NVARCHAR(MAX) NULL             -- JSON con estado después de cambio
);
GO

-- ========================================
-- Tabla: DBError (registro de errores de SQL Server)
-- ========================================
CREATE TABLE dbo.DBError (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserName NVARCHAR(50),
    Number INT,
    State INT,
    Severity INT,
    Line INT,
    ProcedureName NVARCHAR(255),
    Message NVARCHAR(4000),
    DateTime DATETIME DEFAULT GETDATE()
);
GO
