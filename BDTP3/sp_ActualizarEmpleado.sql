USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ActualizarEmpleado
(
    @inIdEmpleado INT,
    @inNombre NVARCHAR(100),
    @inIdTipoIdentificacion INT,
    @inValorDocumentoIdentidad NVARCHAR(30),
    @inFechaNacimiento DATE,
    @inIdPuesto INT,
    @inIdDepartamento INT,
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Empleado
        SET 
            Nombre = @inNombre,
            IdTipoIdentificacion = @inIdTipoIdentificacion,
            ValorDocumentoIdentidad = @inValorDocumentoIdentidad,
            FechaNacimiento = @inFechaNacimiento,
            IdPuesto = @inIdPuesto,
            IdDepartamento = @inIdDepartamento
        WHERE Id = @inIdEmpleado;

        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @outResultCode = ERROR_NUMBER();
    END CATCH;
END;
GO
