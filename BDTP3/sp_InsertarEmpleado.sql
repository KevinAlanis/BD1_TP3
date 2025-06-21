USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_InsertarEmpleado
(
    @inIdPuesto INT,
    @inIdDepartamento INT,
    @inIdTipoIdentificacion INT,
    @inValorDocumentoIdentidad NVARCHAR(30),
    @inNombre NVARCHAR(100),
    @inFechaNacimiento DATE,
    @inIdUsuario INT,
    @inPostBy NVARCHAR(50),
    @inPostInIP NVARCHAR(50),
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Empleado (
            IdPuesto, IdDepartamento, IdTipoIdentificacion,
            ValorDocumentoIdentidad, Nombre, FechaNacimiento,
            IdUsuario, EsActivo, PostBy, PostInIP, PostTime
        )
        VALUES (
            @inIdPuesto, @inIdDepartamento, @inIdTipoIdentificacion,
            @inValorDocumentoIdentidad, @inNombre, @inFechaNacimiento,
            @inIdUsuario, 1, @inPostBy, @inPostInIP, GETDATE()
        );

        -- Aquí podrías insertar las deducciones obligatorias
        -- usando SCOPE_IDENTITY() si deseas.

        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @outResultCode = ERROR_NUMBER();
    END CATCH;
END;
GO
