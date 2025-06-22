ALTER PROCEDURE dbo.CalculoPlanillaSemanal
    @IdSemana INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @FechaFinSemana DATE, @FechaInicioSemana DATE;
        DECLARE @RangoInicio DATETIME, @RangoFin DATETIME;
        DECLARE @IdMes INT;
        DECLARE @EsUltimaSemanaMes BIT;

        -- Obtener la fecha fin (jueves) de la semana planilla
        SELECT @FechaFinSemana = FechaFin
        FROM dbo.Semana
        WHERE Id = @IdSemana;

        -- Calcular el inicio y fin del rango planilla
        -- Rango: viernes anterior 6:00 am hasta jueves 10:00 pm
        -- Calcular rango planilla
		SET @RangoInicio = DATEADD(HOUR, 6, CAST(DATEADD(DAY, -6, @FechaFinSemana) AS DATETIME));
		SET @RangoFin = DATEADD(HOUR, 22, CAST(@FechaFinSemana AS DATETIME));


        -- Determinar el mes planilla asociado
        SELECT TOP 1 @IdMes = Id
        FROM dbo.Mes
        WHERE @RangoInicio BETWEEN FechaInicio AND FechaFin;

        -- Determinar si es última semana del mes (último jueves)
        DECLARE @UltimoJueves DATE;
        SELECT @UltimoJueves = MAX(S.FechaFin)
        FROM dbo.Semana S
        INNER JOIN dbo.Mes M ON S.FechaFin BETWEEN M.FechaInicio AND M.FechaFin
        WHERE M.Id = @IdMes AND DATENAME(WEEKDAY, S.FechaFin) = 'Thursday';

        IF @FechaFinSemana = @UltimoJueves
            SET @EsUltimaSemanaMes = 1;
        ELSE
            SET @EsUltimaSemanaMes = 0;

        -- Procesar por empleado
        DECLARE EmpleadoCursor CURSOR FOR
        SELECT DISTINCT A.IdEmpleado
        FROM dbo.Asistencia A
        WHERE A.FechaSalida >= @RangoInicio AND A.FechaSalida <= @RangoFin;

        DECLARE @IdEmpleado INT;
        OPEN EmpleadoCursor;
        FETCH NEXT FROM EmpleadoCursor INTO @IdEmpleado;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRANSACTION;

            DECLARE @SalarioHora DECIMAL(10,2);
            DECLARE @SalarioBruto DECIMAL(10,2) = 0;
            DECLARE @TotalDeducciones DECIMAL(10,2) = 0;
            DECLARE @SalarioNeto DECIMAL(10,2) = 0;
            DECLARE @HorasOrdinarias DECIMAL(10,2) = 0;
            DECLARE @HorasExtraNormales DECIMAL(10,2) = 0;
            DECLARE @HorasExtraDobles DECIMAL(10,2) = 0;

            SELECT @SalarioHora = P.SalarioxHora
            FROM dbo.Empleado E
            INNER JOIN dbo.Puesto P ON E.IdPuesto = P.Id
            WHERE E.Id = @IdEmpleado;

            -- Procesar asistencias del empleado en el rango
            DECLARE AsisCursor CURSOR FOR
            SELECT Id, FechaEntrada, FechaSalida
            FROM dbo.Asistencia
            WHERE IdEmpleado = @IdEmpleado AND FechaSalida >= @RangoInicio AND FechaSalida <= @RangoFin;

            DECLARE @IdAsistencia INT, @Entrada DATETIME, @Salida DATETIME;

            OPEN AsisCursor;
            FETCH NEXT FROM AsisCursor INTO @IdAsistencia, @Entrada, @Salida;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @IdTipoJornada INT, @HoraInicio TIME, @HoraFin TIME;
                SELECT @IdTipoJornada = J.IdTipoJornada
                FROM dbo.JornadaPorSemana J
                WHERE J.IdEmpleado = @IdEmpleado AND J.IdSemana = @IdSemana;

                SELECT @HoraInicio = TJ.HoraInicio, @HoraFin = TJ.HoraFin
                FROM dbo.TipoJornada TJ
                WHERE TJ.Id = @IdTipoJornada;

                DECLARE @FechaHoraInicio DATETIME = CAST(CAST(@Entrada AS DATE) AS DATETIME) + CAST(@HoraInicio AS DATETIME);
                DECLARE @FechaHoraFin DATETIME = CAST(CAST(@Entrada AS DATE) AS DATETIME) + CAST(@HoraFin AS DATETIME);
                IF @HoraFin < @HoraInicio
                    SET @FechaHoraFin = DATEADD(DAY, 1, @FechaHoraFin);

                -- Calcular horas ordinarias
                DECLARE @HorasOrdinariasTmp DECIMAL(10,2) = DATEDIFF(MINUTE, 
                    CASE WHEN @Entrada > @FechaHoraInicio THEN @Entrada ELSE @FechaHoraInicio END, 
                    CASE WHEN @Salida < @FechaHoraFin THEN @Salida ELSE @FechaHoraFin END
                ) / 60.0;

                IF @HorasOrdinariasTmp < 0 SET @HorasOrdinariasTmp = 0;
                SET @HorasOrdinariasTmp = FLOOR(@HorasOrdinariasTmp);

                SET @HorasOrdinarias += @HorasOrdinariasTmp;
                SET @SalarioBruto += @HorasOrdinariasTmp * @SalarioHora;

                INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, Horas, IdSemana, IdMes)
                VALUES (@IdEmpleado, 1, CAST(@Salida AS DATE), @HorasOrdinariasTmp * @SalarioHora, @HorasOrdinariasTmp, @IdSemana, @IdMes);

                -- Calcular horas extra
                IF @Salida > @FechaHoraFin
                BEGIN
                    DECLARE @HorasExtra DECIMAL(10,2) = FLOOR(DATEDIFF(MINUTE, @FechaHoraFin, @Salida) / 60.0);
                    DECLARE @EsFeriado BIT = CASE WHEN EXISTS (SELECT 1 FROM dbo.Feriado WHERE Fecha = CAST(@Salida AS DATE)) THEN 1 ELSE 0 END;
                    DECLARE @EsDomingo BIT = CASE WHEN DATENAME(WEEKDAY, @Salida) = 'Sunday' THEN 1 ELSE 0 END;

                    IF @EsFeriado = 1 OR @EsDomingo = 1
                    BEGIN
                        SET @HorasExtraDobles += @HorasExtra;
                        SET @SalarioBruto += @HorasExtra * @SalarioHora * 2;
                        INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, Horas, IdSemana, IdMes)
                        VALUES (@IdEmpleado, 3, CAST(@Salida AS DATE), @HorasExtra * @SalarioHora * 2, @HorasExtra, @IdSemana, @IdMes);
                    END
                    ELSE
                    BEGIN
                        SET @HorasExtraNormales += @HorasExtra;
                        SET @SalarioBruto += @HorasExtra * @SalarioHora * 1.5;
                        INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, Horas, IdSemana, IdMes)
                        VALUES (@IdEmpleado, 2, CAST(@Salida AS DATE), @HorasExtra * @SalarioHora * 1.5, @HorasExtra, @IdSemana, @IdMes);
                    END
                END

                FETCH NEXT FROM AsisCursor INTO @IdAsistencia, @Entrada, @Salida;
            END
            CLOSE AsisCursor;
            DEALLOCATE AsisCursor;

            -- Aplicar deducciones
            DECLARE @SemanasMes INT = (SELECT COUNT(*) FROM dbo.Semana S WHERE S.FechaFin BETWEEN (SELECT FechaInicio FROM dbo.Mes WHERE Id = @IdMes) AND (SELECT FechaFin FROM dbo.Mes WHERE Id = @IdMes));

            -- Porcentuales
            DECLARE DedCursor CURSOR FOR
            SELECT DE.IdTipoDeduccion, TD.Valor
            FROM dbo.DeduccionEmpleado DE
            INNER JOIN dbo.TipoDeduccion TD ON DE.IdTipoDeduccion = TD.Id
            WHERE DE.IdEmpleado = @IdEmpleado AND TD.Porcentual = 'Si';

            DECLARE @IdTipoDeduccion INT, @Porcentaje DECIMAL(10,5);
            OPEN DedCursor;
            FETCH NEXT FROM DedCursor INTO @IdTipoDeduccion, @Porcentaje;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @Monto DECIMAL(10,2) = ROUND(@SalarioBruto * @Porcentaje, 2);
                SET @TotalDeducciones += @Monto;
                INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, IdSemana, IdMes)
                VALUES (@IdEmpleado, @IdTipoDeduccion, @FechaFinSemana, -@Monto, @IdSemana, @IdMes);
                FETCH NEXT FROM DedCursor INTO @IdTipoDeduccion, @Porcentaje;
            END
            CLOSE DedCursor;
            DEALLOCATE DedCursor;

            -- Fijas
            DECLARE FixCursor CURSOR FOR
            SELECT DE.IdTipoDeduccion, DE.ValorFijo
            FROM dbo.DeduccionEmpleado DE
            INNER JOIN dbo.TipoDeduccion TD ON DE.IdTipoDeduccion = TD.Id
            WHERE DE.IdEmpleado = @IdEmpleado AND TD.Porcentual = 'No';

            DECLARE @MontoFijo DECIMAL(10,2);
            OPEN FixCursor;
            FETCH NEXT FROM FixCursor INTO @IdTipoDeduccion, @MontoFijo;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @MontoSemanal DECIMAL(10,2) = ROUND(@MontoFijo / @SemanasMes, 2);
                SET @TotalDeducciones += @MontoSemanal;
                INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, IdSemana, IdMes)
                VALUES (@IdEmpleado, @IdTipoDeduccion, @FechaFinSemana, -@MontoSemanal, @IdSemana, @IdMes);
                FETCH NEXT FROM FixCursor INTO @IdTipoDeduccion, @MontoFijo;
            END
            CLOSE FixCursor;
            DEALLOCATE FixCursor;

            -- Insertar resumen semanal
            SET @SalarioNeto = @SalarioBruto - @TotalDeducciones;
            INSERT INTO dbo.PlanillaSemEmpleado (IdEmpleado, IdSemana, SalarioBruto, TotalDeducciones, SalarioNeto,
                                                 HorasOrdinarias, HorasExtraNormales, HorasExtraDobles)
            VALUES (@IdEmpleado, @IdSemana, @SalarioBruto, @TotalDeducciones, @SalarioNeto,
                    @HorasOrdinarias, @HorasExtraNormales, @HorasExtraDobles);

            -- Log
            INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, Parametros, Antes, Despues)
            VALUES (3, 2, CONCAT(N'IdEmpleado=', @IdEmpleado, N', IdSemana=', @IdSemana), NULL,
                    CONCAT(N'SalarioBruto=', @SalarioBruto, N', Neto=', @SalarioNeto));

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
