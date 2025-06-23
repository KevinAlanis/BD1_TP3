USE BDTP31
GO

CREATE OR ALTER PROCEDURE sp_ConsultarPlanillaSemanal
    @IdUsuario INT
AS
BEGIN
    SELECT TOP 15 PSE.IdSemana, S.FechaInicio, S.FechaFin,
           PSE.SalarioBruto, PSE.TotalDeducciones, PSE.SalarioNeto,
           PSE.HorasOrdinarias, PSE.HorasExtraNormales, PSE.HorasExtraDobles
    FROM dbo.PlanillaSemEmpleado PSE
    INNER JOIN dbo.Empleado E ON E.Id = PSE.IdEmpleado
    INNER JOIN dbo.Semana S ON S.Id = PSE.IdSemana
    WHERE E.IdUsuario = @IdUsuario
    ORDER BY S.FechaFin DESC;
END;
