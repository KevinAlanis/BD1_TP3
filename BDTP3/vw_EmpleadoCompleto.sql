CREATE OR ALTER VIEW vw_EmpleadoCompleto AS
SELECT
    e.ID,
    e.Nombre,
    e.IdTipoIdentificacion,
    e.ValorDocumentoIdentidad,
    e.FechaNacimiento,
    e.IdUsuario,
    u.Username,
    u.Password,
    e.IdPuesto,
    p.Nombre AS NombrePuesto,
    e.IdDepartamento,
    d.Nombre AS NombreDepartamento,
    e.EsActivo,
    e.PostInIP,
    e.PostBy,
    e.PostTime
FROM 
    dbo.Empleado e
INNER JOIN 
    dbo.Puesto p ON e.IdPuesto = p.ID
INNER JOIN 
    dbo.Departamento d ON e.IdDepartamento = d.ID
INNER JOIN 
    dbo.Usuario u ON e.IdUsuario = u.ID;


SELECT * FROM vw_EmpleadoCompleto WHERE IdPuesto = 12;
