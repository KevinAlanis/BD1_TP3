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

-- Verifica eventosbitacora
SELECT COUNT(*) AS BitacoraEvento FROM dbo.BitacoraEvento;
SELECT * FROM dbo.BitacoraEvento;
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


-------------------------------------------------------------
-- Marcas de asistencia
SELECT COUNT(*) AS TotalMarcas FROM dbo.Asistencia;
SELECT * FROM dbo.Asistencia;

-- Deducciones de empleado
SELECT COUNT(*) AS TotalDeducciones FROM dbo.DeduccionEmpleado;
SELECT * FROM dbo.DeduccionEmpleado;

-- Jornadas por semana
SELECT COUNT(*) AS TotalJornadas FROM dbo.JornadaPorSemana;
SELECT * FROM dbo.JornadaPorSemana;

-- Empleados
SELECT COUNT(*) AS TotalEmpleados FROM dbo.Empleado;
SELECT * FROM dbo.Empleado;

-- Usuarios
SELECT COUNT(*) AS TotalUsuarios FROM dbo.Usuario;
SELECT * FROM dbo.Usuario;

-- Movimientos de planilla
SELECT COUNT(*) AS TotalMovimientos FROM dbo.MovimientoPlanilla;
SELECT * FROM dbo.MovimientoPlanilla;

-- Movimientos de planilla
SELECT COUNT(*) AS Semana FROM dbo.Semana;
SELECT * FROM dbo.Semana;

-- Movimientos de planilla
SELECT COUNT(*) AS Mes FROM dbo.Mes;
SELECT * FROM dbo.Mes;


SELECT *
FROM dbo.BitacoraEvento
ORDER BY FechaHora ASC;

-- Listar empleados sin filtros
EXEC dbo.sp_ListarEmpleados;

-- Listar empleados con filtro por nombre
EXEC dbo.sp_ListarEmpleados
    @inNombre = 'Carlos Wein';


-- Inserta un empleado de prueba para disparar el trigger
DECLARE @resultCode INT;

PRINT '--- INSERT 1: NUEVO EMPLEADO (DEBE SER EXITOSO) ---';
EXEC dbo.sp_InsertarEmpleado
    @inIdPuesto = 12,
    @inIdDepartamento = 1,
    @inIdTipoIdentificacion = 1,
    @inValorDocumentoIdentidad = 'CedFaPrueba',
    @inNombre = 'Fany Alanis',
    @inFechaNacimiento = '1998-02-24',
    @inUsername = 'random1',
    @inPassword = '1234',
    @inPostBy = 'admin',
    @inPostInIP = '192.168.1.100',
    @outResultCode = @resultCode OUTPUT;
SELECT @resultCode AS ResultCode;

-- Ver los datos insertados (debería haber solo el primer empleado)
PRINT '--- EMPLEADOS ACTUALES ---';
SELECT * FROM dbo.Empleado ORDER BY Id DESC;

PRINT '--- USUARIOS ACTUALES ---';
SELECT * FROM dbo.Usuario ORDER BY Id DESC;

-- Verifica deducciones asociadas
SELECT * FROM dbo.DeduccionEmpleado ORDER BY IdEmpleado DESC; 

-- Verifica bitácora
SELECT * FROM dbo.BitacoraEvento ORDER BY FechaHora DESC;

