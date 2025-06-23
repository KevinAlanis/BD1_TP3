CREATE OR ALTER PROCEDURE dbo.CalculoPlanillaMensual
    @IdSemanaCierre INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @FechaFinSemana DATE, @RangoInicio DATETIME, @RangoFin DATETIME;
        DECLARE @IdMes INT;

        -- Obtener la fecha fin de la semana de cierre
        SELECT @FechaFinSemana = FechaFin
        FROM dbo.Semana
        WHERE Id = @IdSemanaCierre;

        -- Calcular el rango real del mes planilla (viernes 6 am al jueves 10 pm)
        SET @RangoFin = DATEADD(HOUR, 22, CAST(@FechaFinSemana AS DATETIME)); -- jueves 10 pm
        SET @RangoInicio = DATEADD(HOUR, 6, CAST(DATEADD(DAY, -6, @FechaFinSemana) AS DATETIME)); -- viernes anterior 6 am

        -- Determinar el mes planilla asociado
        SELECT TOP 1 @IdMes = Id
        FROM dbo.Mes
        WHERE @RangoFin BETWEEN FechaInicio AND FechaFin;

        -- Procesar por empleado
        DECLARE EmpleadoCursor CURSOR FOR
        SELECT DISTINCT IdEmpleado
        FROM dbo.PlanillaSemEmpleado
        WHERE IdSemana IN (
            SELECT Id FROM dbo.Semana
            WHERE FechaFin >= CAST(@RangoInicio AS DATE) AND FechaFin <= CAST(@RangoFin AS DATE)
        );

        DECLARE @IdEmpleado INT;
        OPEN EmpleadoCursor;
        FETCH NEXT FROM EmpleadoCursor INTO @IdEmpleado;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRANSACTION;

            DECLARE @SalarioBrutoMensual DECIMAL(10,2) = 0;
            DECLARE @TotalDeduccionesMensuales DECIMAL(10,2) = 0;
            DECLARE @SalarioNetoMensual DECIMAL(10,2) = 0;

            -- Sumar planillas semanales dentro del rango
            SELECT 
                @SalarioBrutoMensual = SUM(SalarioBruto),
                @TotalDeduccionesMensuales = SUM(TotalDeducciones)
            FROM dbo.PlanillaSemEmpleado
            WHERE IdEmpleado = @IdEmpleado AND IdSemana IN (
                SELECT Id FROM dbo.Semana
                WHERE FechaFin >= CAST(@RangoInicio AS DATE) AND FechaFin <= CAST(@RangoFin AS DATE)
            );

            SET @SalarioNetoMensual = @SalarioBrutoMensual - @TotalDeduccionesMensuales;

            -- Insertar o actualizar PlanillaMesEmpleado
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

            -- Procesar deducciones por tipo para DeduccionEmpleadoMes
            DECLARE DedCursor CURSOR FOR
            SELECT IdTipoMovimiento, SUM(ABS(Monto)) AS TotalDeduccion
            FROM dbo.MovimientoPlanilla
            WHERE IdEmpleado = @IdEmpleado
            AND IdSemana IN (
                SELECT Id FROM dbo.Semana
                WHERE FechaFin >= CAST(@RangoInicio AS DATE) AND FechaFin <= CAST(@RangoFin AS DATE)
            )
            AND Monto < 0 -- Solo deducciones
            GROUP BY IdTipoMovimiento;

            DECLARE @IdTipoDeduccion INT, @MontoDeduccion DECIMAL(10,2);

            OPEN DedCursor;
            FETCH NEXT FROM DedCursor INTO @IdTipoDeduccion, @MontoDeduccion;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM dbo.DeduccionEmpleadoMes
                    WHERE IdEmpleado = @IdEmpleado AND IdMes = @IdMes AND IdTipoDeduccion = @IdTipoDeduccion
                )
                BEGIN
                    INSERT INTO dbo.DeduccionEmpleadoMes (IdEmpleado, IdMes, IdTipoDeduccion, MontoAcumulado)
                    VALUES (@IdEmpleado, @IdMes, @IdTipoDeduccion, @MontoDeduccion);
                END
                ELSE
                BEGIN
                    UPDATE dbo.DeduccionEmpleadoMes
                    SET MontoAcumulado = @MontoDeduccion
                    WHERE IdEmpleado = @IdEmpleado AND IdMes = @IdMes AND IdTipoDeduccion = @IdTipoDeduccion;
                END

                FETCH NEXT FROM DedCursor INTO @IdTipoDeduccion, @MontoDeduccion;
            END

            CLOSE DedCursor;
            DEALLOCATE DedCursor;

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
