USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BorrarEmpleado
(
    @inIdEmpleado INT,
    @inPostBy NVARCHAR(50),
    @inPostInIP NVARCHAR(50),
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Capturar el estado actual (antes)
        DECLARE @antes NVARCHAR(MAX);
        SELECT @antes = CONCAT(
            'IdPuesto=', IdPuesto, ', IdDepartamento=', IdDepartamento,
            ', IdTipoIdentificacion=', IdTipoIdentificacion,
            ', ValorDocumentoIdentidad=', ValorDocumentoIdentidad,
            ', Nombre=', Nombre, ', FechaNacimiento=', CONVERT(NVARCHAR(30), FechaNacimiento),
            ', EsActivo=', EsActivo
        )
        FROM dbo.Empleado
        WHERE Id = @inIdEmpleado;

        -- Actualizar (borrado lógico)
        UPDATE dbo.Empleado
        SET 
            EsActivo = 0,
            PostBy = @inPostBy,
            PostInIP = @inPostInIP,
            PostTime = GETDATE()
        WHERE Id = @inIdEmpleado;

        -- Capturar el estado después
        DECLARE @despues NVARCHAR(MAX);
        SELECT @despues = CONCAT(
            'IdPuesto=', IdPuesto, ', IdDepartamento=', IdDepartamento,
            ', IdTipoIdentificacion=', IdTipoIdentificacion,
            ', ValorDocumentoIdentidad=', ValorDocumentoIdentidad,
            ', Nombre=', Nombre, ', FechaNacimiento=', CONVERT(NVARCHAR(30), FechaNacimiento),
            ', EsActivo=', EsActivo
        )
        FROM dbo.Empleado
        WHERE Id = @inIdEmpleado;

        -- Bitácora
        INSERT INTO dbo.BitacoraEvento (
            IdUsuario,
            IdTipoEvento,
            FechaHora,
            IP,
            Parametros,
            Antes,
            Despues
        )
        SELECT 
            IdUsuario,
            6, -- Eliminar empleado
            GETDATE(),
            @inPostInIP,
            CONCAT('IdEmpleado=', @inIdEmpleado),
            @antes,
            @despues
        FROM dbo.Empleado
        WHERE Id = @inIdEmpleado;

        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        INSERT INTO dbo.DBError (
            UserName, Number, State, Severity, Line,
            ProcedureName, Message, DateTime
        )
        SELECT
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE();

        SET @outResultCode = 50008;
    END CATCH;
END;
GO
