-- Verifica si hay puestos registrados
SELECT COUNT(*) AS TotalPuestos FROM dbo.Puesto;
SELECT * FROM dbo.Puesto;

-- Verifica tipos de jornada
SELECT COUNT(*) AS TotalTiposJornada FROM dbo.TipoJornada;
SELECT * FROM dbo.TipoJornada;

-- Verifica tipos de documento
SELECT COUNT(*) AS TotalTiposIdentificacion FROM dbo.TipoIdentificacion;
SELECT * FROM dbo.TipoIdentificacion;

-- Verifica departamentos
SELECT COUNT(*) AS TotalDepartamentos FROM dbo.Departamento;
SELECT * FROM dbo.Departamento;

-- Verifica feriados
SELECT COUNT(*) AS TotalFeriados FROM dbo.Feriado;
SELECT * FROM dbo.Feriado;

-- Verifica tipos de movimiento
SELECT COUNT(*) AS TotalTiposMovimiento FROM dbo.TipoMovimiento;
SELECT * FROM dbo.TipoMovimiento;

-- Verifica tipos de deducción
SELECT COUNT(*) AS TotalTiposDeduccion FROM dbo.TipoDeduccion;
SELECT * FROM dbo.TipoDeduccion;

-- Verifica eventos
SELECT COUNT(*) AS TotalTiposEvento FROM dbo.TipoEvento;
SELECT * FROM dbo.TipoEvento;

-- Verifica errores
SELECT COUNT(*) AS TotalErrores FROM dbo.Error;
SELECT * FROM dbo.Error;

----------------------------------------------------------------------------
-- Conteo de registros en Usuario
SELECT COUNT(*) AS TotalUsuarios FROM dbo.Usuario;
SELECT * FROM dbo.Usuario;

-- Conteo de registros en Empleado
SELECT COUNT(*) AS TotalEmpleados FROM dbo.Empleado;
SELECT * FROM dbo.Empleado;

-- Conteo de registros en MovimientoPlanilla
SELECT COUNT(*) AS TotalMovimientos FROM dbo.MovimientoPlanilla;
SELECT * FROM dbo.MovimientoPlanilla;

-- Conteo de registros en Error
SELECT COUNT(*) AS TotalErrores FROM dbo.Error;
SELECT * FROM dbo.Error;

