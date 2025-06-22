USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LogIn
(
    @inUsername NVARCHAR(50),
    @inPassword NVARCHAR(255),
    @inIP NVARCHAR(50),
    @outResultCode INT OUTPUT,
    @outTipoUsuario INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @outTipoUsuario = NULL;

    BEGIN TRY
        DECLARE @idUsuario INT;
        DECLARE @tipoUsuario INT;

        -- Buscar el usuario y tipo
        SELECT 
            @idUsuario = u.Id,
            @tipoUsuario = u.TipoUsuario
        FROM dbo.Usuario u
        WHERE u.Username = @inUsername;

        -- Validar si el username existe
        IF @idUsuario IS NULL
        BEGIN
            SET @outResultCode = 50001; -- Username no existe

            INSERT INTO dbo.BitacoraEvento (
                IdTipoEvento,
                IdUsuario,
                FechaHora,
                IP,
                Parametros,
                Antes,
                Despues
            )
            VALUES (
                1,
                NULL,
                GETDATE(),
                @inIP,
                CONCAT('Username=', @inUsername),
                '',
                'Intento de login fallido - Username no existe'
            );

            RETURN;
        END

        -- Validar password
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuario u
            WHERE u.Id = @idUsuario AND u.Password = @inPassword
        )
        BEGIN
            SET @outResultCode = 50002; -- Password incorrecta

            INSERT INTO dbo.BitacoraEvento (
                IdTipoEvento,
                IdUsuario,
                FechaHora,
                IP,
                Parametros,
                Antes,
                Despues
            )
            VALUES (
                1,
                @idUsuario,
                GETDATE(),
                @inIP,
                CONCAT('Username=', @inUsername),
                '',
                'Intento de login fallido - Password incorrecta'
            );

            RETURN;
        END

        -- Login exitoso
        SET @outResultCode = 0;
        SET @outTipoUsuario = @tipoUsuario;

        INSERT INTO dbo.BitacoraEvento (
            IdTipoEvento,
            IdUsuario,
            FechaHora,
            IP,
            Parametros,
            Antes,
            Despues
        )
        VALUES (
            1,
            @idUsuario,
            GETDATE(),
            @inIP,
            CONCAT('Username=', @inUsername),
            '',
            'Login exitoso'
        );

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBError (
            UserName, Number, State, Severity, Line, ProcedureName, Message, DateTime
        )
        SELECT 
            SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), 
            ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE();

        SET @outResultCode = 50008; -- Error general
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
