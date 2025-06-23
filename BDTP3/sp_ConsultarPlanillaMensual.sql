USE BDTP31
GO

CREATE OR ALTER PROCEDURE sp_ConsultarPlanillaMensual
    @IdUsuario INT
AS
BEGIN
    SELECT TOP 12 PME.IdMes, M.FechaInicio, M.FechaFin,
           PME.SalarioBrutoMensual, PME.TotalDeduccionesMensuales, PME.SalarioNetoMensual
    FROM dbo.PlanillaMesEmpleado PME
    INNER JOIN dbo.Empleado E ON E.Id = PME.IdEmpleado
    INNER JOIN dbo.Mes M ON M.Id = PME.IdMes
    WHERE E.IdUsuario = @IdUsuario
    ORDER BY M.FechaFin DESC;
END;
