CREATE PROCEDURE dbo.CalculoPlanillaMensual
    @IdMes INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Identificar el rango del mes planilla: primer viernes tras último jueves del mes anterior a último jueves actual
        DECLARE @FechaInicioMes DATE, @FechaFinMes DATE;

        -- Último jueves del mes anterior
        DECLARE @UltimoJuevesMesAnterior DATE;
        SELECT @UltimoJuevesMesAnterior = MAX(S.FechaFin)
        FROM dbo.Semana S
        INNER JOIN dbo.Mes M ON S.FechaFin BETWEEN M.FechaInicio AND M.FechaFin
        WHERE M.Id = @IdMes - 1 AND DATENAME(WEEKDAY, S.FechaFin) = 'Thursday';

        -- Primer viernes tras ese jueves
        SET @FechaInicioMes = DATEADD(DAY, 1, @UltimoJuevesMesAnterior);

        -- Último jueves de este mes
        SELECT @FechaFinMes = MAX(S.FechaFin)
        FROM dbo.Semana S
        INNER JOIN dbo.Mes M ON S.FechaFin BETWEEN M.FechaInicio AND M.FechaFin
        WHERE M.Id = @IdMes AND DATENAME(WEEKDAY, S.FechaFin) = 'Thursday';

        -- Procesar acumulados por empleado
        DECLARE EmpleadoCursor CURSOR FOR
        SELECT DISTINCT IdEmpleado
        FROM dbo.PlanillaSemEmpleado
        WHERE IdSemana IN (
            SELECT Id FROM dbo.Semana WHERE FechaFin >= @FechaInicioMes AND FechaFin <= @FechaFinMes
        );

        DECLARE @IdEmpleado INT;
        OPEN EmpleadoCursor;
        FETCH NEXT FROM EmpleadoCursor INTO @IdEmpleado;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRANSACTION;

            -- Sumar semanas del mes planilla
            DECLARE @SalarioBrutoMensual DECIMAL(10,2) = 0;
            DECLARE @TotalDeduccionesMensuales DECIMAL(10,2) = 0;
            DECLARE @SalarioNetoMensual DECIMAL(10,2) = 0;

            SELECT 
                @SalarioBrutoMensual = SUM(SalarioBruto),
                @TotalDeduccionesMensuales = SUM(TotalDeducciones)
            FROM dbo.PlanillaSemEmpleado
            WHERE IdEmpleado = @IdEmpleado AND IdSemana IN (
                SELECT Id FROM dbo.Semana WHERE FechaFin >= @FechaInicioMes AND FechaFin <= @FechaFinMes
            );

            SET @SalarioNetoMensual = @SalarioBrutoMensual - @TotalDeduccionesMensuales;

            -- Verificar si ya existe el mes planilla
            IF NOT EXISTS (
                SELECT 1 FROM dbo.PlanillaMesEmpleado WHERE IdEmpleado = @IdEmpleado AND IdMes = @IdMes
            )
            BEGIN
                INSERT INTO dbo.PlanillaMesEmpleado (IdEmpleado, IdMes, SalarioBrutoMensual, TotalDeduccionesMensuales, SalarioNetoMensual)
                VALUES (@IdEmpleado, @IdMes, @SalarioBrutoMensual, @TotalDeduccionesMensuales, @SalarioNetoMensual);
            END
            ELSE
            BEGIN
                UPDATE dbo.PlanillaMesEmpleado
                SET SalarioBrutoMensual = @SalarioBrutoMensual,
                    TotalDeduccionesMensuales = @TotalDeduccionesMensuales,
                    SalarioNetoMensual = @SalarioNetoMensual
                WHERE IdEmpleado = @IdEmpleado AND IdMes = @IdMes;
            END

            -- Log bitácora
            INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, Parametros, Antes, Despues)
            VALUES (3, 3, 
                    CONCAT(N'IdEmpleado=', @IdEmpleado, N', IdMes=', @IdMes),
                    NULL,
                    CONCAT(N'SalarioBrutoMensual=', CONVERT(NVARCHAR(50), @SalarioBrutoMensual),
                           N', Neto=', CONVERT(NVARCHAR(50), @SalarioNetoMensual)));

            COMMIT;

            FETCH NEXT FROM EmpleadoCursor INTO @IdEmpleado;
        END

        CLOSE EmpleadoCursor;
        DEALLOCATE EmpleadoCursor;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;
        INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, ProcedureName, Message)
        VALUES (SYSTEM_USER, ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE());
        THROW;
    END CATCH
END;
