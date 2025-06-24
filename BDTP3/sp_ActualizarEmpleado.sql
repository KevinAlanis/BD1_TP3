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
    @inPostBy NVARCHAR(50),
    @inPostInIP NVARCHAR(50),
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar que el nombre sea alfabético (permitiendo espacios)
        IF @inNombre LIKE '%[^A-Za-z ]%'
        BEGIN
            SET @outResultCode = 50009; -- Nombre no alfabético
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Validar que el valor del documento permita letras, números y guiones
        IF @inValorDocumentoIdentidad LIKE '%[^A-Za-z0-9-]%'
        BEGIN
            SET @outResultCode = 50010; -- Documento no válido
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Validar cédula duplicada en otro empleado
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado 
            WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad 
            AND Id <> @inIdEmpleado
        )
        BEGIN
            SET @outResultCode = 50006; -- Cédula duplicada
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Validar nombre duplicado en otro empleado
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado 
            WHERE Nombre = @inNombre 
            AND Id <> @inIdEmpleado
        )
        BEGIN
            SET @outResultCode = 50007; -- Nombre duplicado
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Capturar el estado actual (antes)
        DECLARE @antes NVARCHAR(MAX);
        SELECT @antes = CONCAT(
            'IdPuesto=', IdPuesto, ', IdDepartamento=', IdDepartamento,
            ', IdTipoIdentificacion=', IdTipoIdentificacion,
            ', ValorDocumentoIdentidad=', ValorDocumentoIdentidad,
            ', Nombre=', Nombre, ', FechaNacimiento=', CONVERT(NVARCHAR(30), FechaNacimiento)
        )
        FROM dbo.Empleado
        WHERE Id = @inIdEmpleado;

        -- Actualizar el empleado
        UPDATE dbo.Empleado
        SET 
            Nombre = @inNombre,
            IdTipoIdentificacion = @inIdTipoIdentificacion,
            ValorDocumentoIdentidad = @inValorDocumentoIdentidad,
            FechaNacimiento = @inFechaNacimiento,
            IdPuesto = @inIdPuesto,
            IdDepartamento = @inIdDepartamento,
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
            ', Nombre=', Nombre, ', FechaNacimiento=', CONVERT(NVARCHAR(30), FechaNacimiento)
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
            7, -- Editar empleado
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
