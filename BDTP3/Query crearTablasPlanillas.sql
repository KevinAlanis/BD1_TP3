USE BDTP31;
GO

-- ========================================
-- Tabla: Semana
-- ========================================
CREATE TABLE dbo.Semana (
    Id INT PRIMARY KEY,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL
);
GO

-- ========================================
-- Tabla: Mes
-- ========================================
CREATE TABLE dbo.Mes (
    Id INT PRIMARY KEY,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL
);
GO

-- ========================================
-- Tabla: PlanillaSemEmpleado
-- ========================================
CREATE TABLE dbo.PlanillaSemEmpleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(Id),
    IdSemana INT NOT NULL FOREIGN KEY REFERENCES dbo.Semana(Id),
    SalarioBruto DECIMAL(10,2) NOT NULL,
    TotalDeducciones DECIMAL(10,2) NOT NULL,
    SalarioNeto DECIMAL(10,2) NOT NULL,
    HorasOrdinarias DECIMAL(10,2) NOT NULL,
    HorasExtraNormales DECIMAL(10,2) NOT NULL,
    HorasExtraDobles DECIMAL(10,2) NOT NULL,
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL,
    CONSTRAINT UQ_PlanillaSemana UNIQUE (IdEmpleado, IdSemana)
);
GO

-- ========================================
-- Tabla: PlanillaMesEmpleado
-- ========================================
CREATE TABLE dbo.PlanillaMesEmpleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(Id),
    IdMes INT NOT NULL FOREIGN KEY REFERENCES dbo.Mes(Id),
    SalarioBrutoMensual DECIMAL(10,2) NOT NULL,
    TotalDeduccionesMensuales DECIMAL(10,2) NOT NULL,
    SalarioNetoMensual DECIMAL(10,2) NOT NULL,
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL,
    CONSTRAINT UQ_PlanillaMes UNIQUE (IdEmpleado, IdMes)
);
GO

-- ========================================
-- Tabla: MovimientoPlanilla
-- ========================================
CREATE TABLE dbo.MovimientoPlanilla (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(Id),
    IdTipoMovimiento INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoMovimiento(Id),
    Fecha DATE NOT NULL,
    Monto DECIMAL(10,2) NOT NULL,
    Horas DECIMAL(10,2) NULL,
    IdSemana INT NULL FOREIGN KEY REFERENCES dbo.Semana(Id),
    IdMes INT NULL FOREIGN KEY REFERENCES dbo.Mes(Id),
    PostInIP NVARCHAR(50) NULL,
    PostBy NVARCHAR(50) NULL,
    PostTime DATETIME NULL
);
GO

-- ========================================
-- Tabla: DeduccionEmpleado
-- ========================================
CREATE TABLE dbo.DeduccionEmpleado (
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(Id),
    IdTipoDeduccion INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoDeduccion(Id),
    ValorFijo DECIMAL(10,2) NULL,
	FechaAsociacion DATE NOT NULL,
    PRIMARY KEY (IdEmpleado, IdTipoDeduccion, FechaAsociacion)
);
GO

-- ========================================
-- Tabla: DeduccionEmpleadoMes
-- ========================================
CREATE TABLE dbo.DeduccionEmpleadoMes (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(Id),
    IdTipoDeduccion INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoDeduccion(Id),
    IdMes INT NOT NULL FOREIGN KEY REFERENCES dbo.Mes(Id),
    MontoAcumulado DECIMAL(10,2) NOT NULL
);
GO
