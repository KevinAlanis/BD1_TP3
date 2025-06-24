USE BDTP31
GO

CREATE OR ALTER PROCEDURE dbo.ProcesarPlanillaCompletaRango
    @FechaInicioRango DATE,
    @FechaFinRango DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE SemanaCursor CURSOR FOR
        SELECT Id
        FROM dbo.Semana
        WHERE FechaFin BETWEEN @FechaInicioRango AND @FechaFinRango
        ORDER BY FechaFin;

        DECLARE @IdSemana INT;

        OPEN SemanaCursor;
        FETCH NEXT FROM SemanaCursor INTO @IdSemana;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Ejecuta el proceso de la semana específica
			PRINT 'Procesando semana Id=' + CAST(@IdSemana AS NVARCHAR);
            EXEC dbo.ProcesarPlanillaCompleta @IdSemana = @IdSemana;

            FETCH NEXT FROM SemanaCursor INTO @IdSemana;
        END

        CLOSE SemanaCursor;
        DEALLOCATE SemanaCursor;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;
        INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, ProcedureName, Message, DateTime)
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        THROW;
    END CATCH
END;
