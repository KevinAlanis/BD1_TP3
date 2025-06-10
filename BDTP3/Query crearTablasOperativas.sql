USE BDTP31;
GO

-- ========================================
-- Tabla: Usuario
-- ========================================
CREATE TABLE dbo.Usuario (
    Id INT PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL,
    Password NVARCHAR(255) NOT NULL,
    TipoUsuario INT NOT NULL, -- 1 = Admin, 2 = Empleado, 3 = Script (Sistema)
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL
);
GO

-- ========================================
-- Tabla: Empleado
-- ========================================
CREATE TABLE dbo.Empleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdPuesto INT NOT NULL FOREIGN KEY REFERENCES dbo.Puesto(Id),
    IdDepartamento INT NOT NULL FOREIGN KEY REFERENCES dbo.Departamento(Id),
    IdTipoIdentificacion INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoIdentificacion(Id),
    ValorDocumentoIdentidad NVARCHAR(30) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    IdUsuario INT NOT NULL FOREIGN KEY REFERENCES dbo.Usuario(Id),
    EsActivo BIT NOT NULL DEFAULT 1,
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL
);
GO

-- ========================================
-- Tabla: Asistencia
-- ========================================
CREATE TABLE dbo.Asistencia (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(Id),
    FechaEntrada DATETIME NOT NULL,
    FechaSalida DATETIME NULL,
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL
);
GO

-- ========================================
-- Tabla: JornadaPorSemana
-- ========================================
CREATE TABLE dbo.JornadaPorSemana (
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(Id),
    IdSemana INT NOT NULL,
    IdTipoJornada INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoJornada(Id),
    PRIMARY KEY (IdEmpleado, IdSemana)
);
GO
