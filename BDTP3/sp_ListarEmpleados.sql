USE BDTP31;
GO
CREATE OR ALTER PROCEDURE dbo.sp_ListarEmpleados
(
    @inNombre NVARCHAR(100) = NULL,
    @inIdDepartamento INT = NULL,
    @inIdPuesto INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.Nombre,
        e.ValorDocumentoIdentidad,
        e.FechaNacimiento,
        p.Nombre AS NombrePuesto,
        d.Nombre AS NombreDepartamento,
        t.Nombre AS NombreTipoIdentificacion,
        u.Username AS NombreUsuario,
        e.PostBy,
        e.PostInIP,
        e.PostTime
    FROM dbo.Empleado e
    INNER JOIN dbo.Puesto p ON e.IdPuesto = p.Id
    INNER JOIN dbo.Departamento d ON e.IdDepartamento = d.Id
    INNER JOIN dbo.TipoIdentificacion t ON e.IdTipoIdentificacion = t.Id
    INNER JOIN dbo.Usuario u ON e.IdUsuario = u.Id
    WHERE e.EsActivo = 1
      AND (@inNombre IS NULL OR e.Nombre LIKE '%' + @inNombre + '%')
      AND (@inIdDepartamento IS NULL OR e.IdDepartamento = @inIdDepartamento)
      AND (@inIdPuesto IS NULL OR e.IdPuesto = @inIdPuesto)
    ORDER BY e.Nombre ASC;
END;
GO
