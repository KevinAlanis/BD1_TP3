USE BDTP31
GO

CREATE OR ALTER PROCEDURE sp_ConsultarDetalleMovimientosSemanal
    @IdUsuario INT,
    @IdSemana INT
AS
BEGIN
    SELECT A.FechaEntrada, A.FechaSalida, 
           MP.IdTipoMovimiento, TM.Nombre AS TipoMovimiento,
           MP.Horas, MP.Monto
    FROM dbo.Asistencia A
    INNER JOIN dbo.MovimientoPlanilla MP ON MP.IdEmpleado = A.IdEmpleado AND CAST(MP.Fecha AS DATE) = CAST(A.FechaSalida AS DATE)
    INNER JOIN dbo.TipoMovimiento TM ON TM.Id = MP.IdTipoMovimiento
    INNER JOIN dbo.Empleado E ON E.Id = A.IdEmpleado
    WHERE E.IdUsuario = @IdUsuario
      AND MP.IdSemana = @IdSemana
    ORDER BY A.FechaEntrada;
END;
