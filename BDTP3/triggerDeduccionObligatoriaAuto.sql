USE BDTP31;
GO

CREATE OR ALTER TRIGGER trg_InsertEmpleado_AsociarDeducciones
ON dbo.Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Insertar las deducciones obligatorias para el empleado nuevo
        INSERT INTO dbo.DeduccionEmpleado (IdEmpleado, IdTipoDeduccion, ValorFijo)
        SELECT 
            I.Id,
            TD.Id,
            TD.Valor
        FROM inserted I
        CROSS JOIN dbo.TipoDeduccion TD
        WHERE TD.Obligatorio = 'Si'
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.DeduccionEmpleado DE 
            WHERE DE.IdEmpleado = I.Id AND DE.IdTipoDeduccion = TD.Id
        );

        -- Insertar en bitácora detallando deducciones asociadas
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
            I.IdUsuario,
            8, -- Asociar deducción
            GETDATE(),
            '', -- No IP disponible en trigger
            CONCAT('IdEmpleado=', I.Id),
            '',
            STRING_AGG(CONCAT('IdTipoDeduccion=', TD.Id, ', ValorFijo=', TD.Valor), '; ')
        FROM inserted I
        CROSS JOIN dbo.TipoDeduccion TD
        WHERE TD.Obligatorio = 'Si'
        GROUP BY I.Id, I.IdUsuario;

    END TRY
    BEGIN CATCH
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

        THROW; 
    END CATCH
END;
GO
