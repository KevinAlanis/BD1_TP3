
SELECT * FROM Semana;
SELECT * FROM Mes;
SELECT * FROM PlanillaSemEmpleado;
SELECT * FROM PlanillaMesEmpleado;
SELECT * FROM MovimientoPlanilla;
SELECT * FROM DeduccionEmpleado;


EXEC dbo.CalculoPlanillaMensual @IdSemanaCierre = 5;

SELECT * FROM DeduccionEmpleadoMes
SELECT * FROM PlanillaMesEmpleado
SELECT * FROM PlanillaSemEmpleado
SELECT * FROM BitacoraEvento
SELECT * FROM MovimientoPlanilla ORDER BY Fecha ASC


EXEC dbo.ProcesarPlanillaCompleta @IdSemana = 9;
-- Ver los encabezados de planilla semanal creados
SELECT 
    IdEmpleado,
    IdSemana,
    SalarioBruto,
    TotalDeducciones,
    SalarioNeto,
    HorasOrdinarias,
    HorasExtraNormales,
    HorasExtraDobles
FROM dbo.PlanillaSemEmpleado
WHERE IdSemana = 8
ORDER BY IdEmpleado;

--Ver los encabezados de planilla mensual creados
SELECT 
    IdEmpleado,
    IdMes,
    SalarioBrutoMensual,
    TotalDeduccionesMensuales,
    SalarioNetoMensual
FROM dbo.PlanillaMesEmpleado
WHERE IdMes = 7
ORDER BY IdEmpleado;

--Ver encabezados de deducción empleado mes creados
SELECT 
    IdEmpleado,
    IdMes,
    IdTipoDeduccion,
    MontoAcumulado
FROM dbo.DeduccionEmpleadoMes
WHERE IdMes = 7
ORDER BY IdEmpleado, IdTipoDeduccion;

SELECT