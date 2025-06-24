USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LogOut
(
    @inIdUsuario INT,
    @inIP NVARCHAR(50),
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Insertar en la bitácora el evento de logout
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
            2, -- Tipo de evento logout
            @inIdUsuario,
            GETDATE(),
            @inIP,
            CONCAT('Logout UsuarioId=', @inIdUsuario),
            '',
            'Logout exitoso'
        );

        SET @outResultCode = 0; -- Éxito
    END TRY
    BEGIN CATCH
        -- Registrar error
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

        SET @outResultCode = 50008; -- Código de error general
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
