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
    @inUsername NVARCHAR(50),
    @inPassword NVARCHAR(255),
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

        -- Validar cédula duplicada
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad
        )
        BEGIN
            SET @outResultCode = 50004; -- Cédula duplicada
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Validar nombre duplicado
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado WHERE Nombre = @inNombre
        )
        BEGIN
            SET @outResultCode = 50005; -- Nombre duplicado
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Calcular IdUsuario nuevo
        DECLARE @nuevoIdUsuario INT;
        SELECT @nuevoIdUsuario = ISNULL(MAX(Id), 0) + 1 FROM dbo.Usuario;

        -- Insertar en Usuario
        INSERT INTO dbo.Usuario (Id, Username, Password, TipoUsuario, PostBy, PostInIP, PostTime)
        VALUES (@nuevoIdUsuario, @inUsername, @inPassword, 2, @inPostBy, @inPostInIP, GETDATE());

        -- Insertar en Empleado
        INSERT INTO dbo.Empleado (
            IdPuesto, IdDepartamento, IdTipoIdentificacion,
            ValorDocumentoIdentidad, Nombre, FechaNacimiento,
            IdUsuario, EsActivo, PostBy, PostInIP, PostTime
        )
        VALUES (
            @inIdPuesto, @inIdDepartamento, @inIdTipoIdentificacion,
            @inValorDocumentoIdentidad, @inNombre, @inFechaNacimiento,
            @nuevoIdUsuario, 1, @inPostBy, @inPostInIP, GETDATE()
        );

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
        VALUES (
            @nuevoIdUsuario,
            5,
            GETDATE(),
            @inPostInIP,
            CONCAT(
                'IdPuesto=', @inIdPuesto, ', IdDepartamento=', @inIdDepartamento,
                ', IdTipoIdentificacion=', @inIdTipoIdentificacion,
                ', ValorDocumentoIdentidad=', @inValorDocumentoIdentidad,
                ', Nombre=', @inNombre, ', FechaNacimiento=', CONVERT(NVARCHAR(30), @inFechaNacimiento),
                ', Username=', @inUsername
            ),
            '',
            CONCAT(
                'IdPuesto=', @inIdPuesto, ', IdDepartamento=', @inIdDepartamento,
                ', IdTipoIdentificacion=', @inIdTipoIdentificacion,
                ', ValorDocumentoIdentidad=', @inValorDocumentoIdentidad,
                ', Nombre=', @inNombre, ', FechaNacimiento=', CONVERT(NVARCHAR(30), @inFechaNacimiento),
                ', IdUsuario=', @nuevoIdUsuario
            )
        );

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
