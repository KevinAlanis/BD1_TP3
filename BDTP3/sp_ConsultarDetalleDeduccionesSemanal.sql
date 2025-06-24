USE BDTP31
GO

CREATE OR ALTER PROCEDURE sp_ConsultarDetalleDeduccionesSemanal
    @IdUsuario INT,
    @IdSemana INT
AS
BEGIN
    SELECT TD.Nombre, 
           CASE WHEN TD.Porcentual = 'Si' THEN TD.Valor ELSE NULL END AS PorcentajeAplicado,
           ABS(MP.Monto) AS MontoDeduccion
    FROM dbo.MovimientoPlanilla MP
    INNER JOIN dbo.TipoDeduccion TD ON TD.Id = MP.IdTipoMovimiento
    INNER JOIN dbo.Empleado E ON E.Id = MP.IdEmpleado
    WHERE E.IdUsuario = @IdUsuario
      AND MP.IdSemana = @IdSemana
      AND MP.Monto < 0;
END;
