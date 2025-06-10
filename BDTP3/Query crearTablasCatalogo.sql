USE BDTP31;
GO

-- ========================================
-- Tabla: TipoIdentificacion
-- ========================================
CREATE TABLE dbo.TipoIdentificacion (
    Id INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL
);
GO

-- ========================================
-- Tabla: TipoJornada
-- ========================================
CREATE TABLE dbo.TipoJornada (
    Id INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL
);
GO

-- ========================================
-- Tabla: TipoMovimiento
-- ========================================
CREATE TABLE dbo.TipoMovimiento (
    Id INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL
);
GO

-- ========================================
-- Tabla: TipoDeduccion
-- ========================================
CREATE TABLE dbo.TipoDeduccion (
    Id INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Obligatorio BIT NOT NULL,
    Porcentual BIT NOT NULL,
    Valor DECIMAL(10,5) NOT NULL
);
GO

-- ========================================
-- Tabla: TipoEvento
-- ========================================
CREATE TABLE dbo.TipoEvento (
    Id INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL
);
GO

-- ========================================
-- Tabla: Departamento
-- ========================================
CREATE TABLE dbo.Departamento (
    Id INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL
);
GO

-- ========================================
-- Tabla: Puesto
-- ========================================
CREATE TABLE dbo.Puesto (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    SalarioxHora DECIMAL(10,2) NOT NULL,
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL
);
GO

-- ========================================
-- Tabla: Feriado
-- ========================================
CREATE TABLE dbo.Feriado (
    Id INT PRIMARY KEY,
    Nombre NVARCHAR(255) NOT NULL,
    Fecha DATE NOT NULL,
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL
);
GO

-- ========================================
-- Tabla: Error (Catálogo de errores)
-- ========================================
CREATE TABLE dbo.Error (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Codigo INT NOT NULL,
    Descripcion NVARCHAR(500) NOT NULL
);
GO