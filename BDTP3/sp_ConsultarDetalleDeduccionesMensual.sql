USE BDTP31
GO

CREATE OR ALTER PROCEDURE sp_ConsultarDetalleDeduccionesMensual
    @IdUsuario INT,
    @IdMes INT
AS
BEGIN
    SELECT TD.Nombre, 
           CASE WHEN TD.Porcentual = 'Si' THEN TD.Valor ELSE NULL END AS PorcentajeAplicado,
           DEM.MontoAcumulado
    FROM dbo.DeduccionEmpleadoMes DEM
    INNER JOIN dbo.TipoDeduccion TD ON TD.Id = DEM.IdTipoDeduccion
    INNER JOIN dbo.Empleado E ON E.Id = DEM.IdEmpleado
    WHERE E.IdUsuario = @IdUsuario
      AND DEM.IdMes = @IdMes;
END;

