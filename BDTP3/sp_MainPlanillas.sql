USE [BDTP31]
GO
/****** Object:  StoredProcedure [dbo].[ProcesarPlanillaCompleta]    Script Date: 23/6/2025 02:20:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE dbo.ProcesarPlanillaCompleta
    @IdSemana INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

		IF @IdSemana = 1
		BEGIN
			PRINT 'La semana 1 se ignora del cálculo de planilla.';
			RETURN;
		END


        DECLARE @FechaFinSemana DATE, @RangoInicio DATETIME, @RangoFin DATETIME, @IdMes INT;

        -- Obtener la fecha fin de la semana
        SELECT @FechaFinSemana = FechaFin
        FROM dbo.Semana
        WHERE Id = @IdSemana;

        -- Calcular rango planilla
        SET @RangoFin = DATEADD(HOUR, 22, CAST(@FechaFinSemana AS DATETIME)); -- jueves 10 pm
        SET @RangoInicio = DATEADD(HOUR, 6, CAST(DATEADD(DAY, -6, @FechaFinSemana) AS DATETIME)); -- viernes 6 am

        -- Determinar el mes planilla
        SELECT TOP 1 @IdMes = Id
        FROM dbo.Mes
        WHERE @RangoFin BETWEEN FechaInicio AND FechaFin;

        BEGIN TRANSACTION;

        -- Crear encabezados PlanillaSemEmpleado
        INSERT INTO dbo.PlanillaSemEmpleado (IdEmpleado, IdSemana, SalarioBruto, TotalDeducciones, SalarioNeto,
                                             HorasOrdinarias, HorasExtraNormales, HorasExtraDobles)
        SELECT E.Id, @IdSemana, 0, 0, 0, 0, 0, 0
        FROM dbo.Empleado E
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.PlanillaSemEmpleado 
            WHERE IdEmpleado = E.Id AND IdSemana = @IdSemana
        );

        -- Crear encabezados PlanillaMesEmpleado
        INSERT INTO dbo.PlanillaMesEmpleado (IdEmpleado, IdMes, SalarioBrutoMensual, TotalDeduccionesMensuales, SalarioNetoMensual)
        SELECT E.Id, @IdMes, 0, 0, 0
        FROM dbo.Empleado E
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.PlanillaMesEmpleado 
            WHERE IdEmpleado = E.Id AND IdMes = @IdMes
        );

        -- Crear encabezados DeduccionEmpleadoMes
        INSERT INTO dbo.DeduccionEmpleadoMes (IdEmpleado, IdMes, IdTipoDeduccion, MontoAcumulado)
        SELECT DE.IdEmpleado, @IdMes, DE.IdTipoDeduccion, 0
        FROM dbo.DeduccionEmpleado DE
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.DeduccionEmpleadoMes 
            WHERE IdEmpleado = DE.IdEmpleado AND IdMes = @IdMes AND IdTipoDeduccion = DE.IdTipoDeduccion
        );

        COMMIT;

        -- Calcular planilla semanal
        EXEC dbo.CalculoPlanillaSemanal @IdSemana;

        -- Si es cierre de mes, calcular planilla mensual
        DECLARE @UltimoJuevesMes DATE;
        SELECT @UltimoJuevesMes = MAX(S.FechaFin)
        FROM dbo.Semana S
        INNER JOIN dbo.Mes M ON S.FechaFin BETWEEN M.FechaInicio AND M.FechaFin
        WHERE M.Id = @IdMes AND DATENAME(WEEKDAY, S.FechaFin) = 'Thursday';

        IF @FechaFinSemana = @UltimoJuevesMes
        BEGIN
            EXEC dbo.CalculoPlanillaMensual @IdSemanaCierre = @IdSemana;
        END

        -- Bitácora
        INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, FechaHora, Parametros, Antes, Despues)
        VALUES (3, 10, GETDATE(), CONCAT('IdSemana=', @IdSemana, ', IdMes=', @IdMes), '', 'Proceso planilla completo ejecutado');

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;
        INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, ProcedureName, Message, DateTime)
        VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        THROW;
    END CATCH
END;
