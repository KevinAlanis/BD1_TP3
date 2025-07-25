USE [BDTP31]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CalculoPlanillaSemanal]
    @IdSemana INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @FechaFinSemana DATE, @RangoInicio DATETIME, @RangoFin DATETIME, @IdMes INT;

        -- Fechas de la semana
        SELECT @FechaFinSemana = FechaFin FROM dbo.Semana WHERE Id = @IdSemana;
        SET @RangoInicio = DATEADD(HOUR, 6, CAST(DATEADD(DAY, -6, @FechaFinSemana) AS DATETIME));
        SET @RangoFin = DATEADD(HOUR, 22, CAST(@FechaFinSemana AS DATETIME));

        -- Mes planilla
        SELECT TOP 1 @IdMes = Id FROM dbo.Mes WHERE @RangoFin BETWEEN FechaInicio AND FechaFin;

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
            SELECT @SalarioHora = P.SalarioxHora
            FROM dbo.Empleado E
            INNER JOIN dbo.Puesto P ON E.IdPuesto = P.Id
            WHERE E.Id = @IdEmpleado;

            IF @SalarioHora IS NULL
            BEGIN
                PRINT CONCAT('⚠ SalarioHora NULL para IdEmpleado=', @IdEmpleado, '. Se omite procesamiento.');
                COMMIT;
                FETCH NEXT FROM EmpleadoCursor INTO @IdEmpleado;
                CONTINUE;
            END

            DECLARE @SalarioBruto DECIMAL(10,2) = 0, @TotalDeducciones DECIMAL(10,2) = 0, @SalarioNeto DECIMAL(10,2) = 0;
            DECLARE @HorasOrdinarias DECIMAL(10,2) = 0, @HorasExtraNormales DECIMAL(10,2) = 0, @HorasExtraDobles DECIMAL(10,2) = 0;

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

                IF @IdTipoJornada IS NULL
                BEGIN
                    PRINT CONCAT('⚠ IdTipoJornada NULL para IdEmpleado=', @IdEmpleado, ' Semana=', @IdSemana);
                    FETCH NEXT FROM AsisCursor INTO @IdAsistencia, @Entrada, @Salida;
                    CONTINUE;
                END

                SELECT @HoraInicio = TJ.HoraInicio, @HoraFin = TJ.HoraFin
                FROM dbo.TipoJornada TJ
                WHERE TJ.Id = @IdTipoJornada;

                IF @HoraInicio IS NULL OR @HoraFin IS NULL
                BEGIN
                    PRINT CONCAT('⚠ Horario NULL para IdEmpleado=', @IdEmpleado, ' Semana=', @IdSemana);
                    FETCH NEXT FROM AsisCursor INTO @IdAsistencia, @Entrada, @Salida;
                    CONTINUE;
                END

                DECLARE @FechaHoraInicio DATETIME = CAST(CAST(@Entrada AS DATE) AS DATETIME) + CAST(@HoraInicio AS DATETIME);
                DECLARE @FechaHoraFin DATETIME = CAST(CAST(@Entrada AS DATE) AS DATETIME) + CAST(@HoraFin AS DATETIME);
                IF @HoraFin < @HoraInicio
                    SET @FechaHoraFin = DATEADD(DAY, 1, @FechaHoraFin);

                DECLARE @HorasOrdinariasTmp DECIMAL(10,2) = DATEDIFF(MINUTE, 
                    CASE WHEN @Entrada > @FechaHoraInicio THEN @Entrada ELSE @FechaHoraInicio END, 
                    CASE WHEN @Salida < @FechaHoraFin THEN @Salida ELSE @FechaHoraFin END
                ) / 60.0;

                IF @HorasOrdinariasTmp < 0 SET @HorasOrdinariasTmp = 0;
                SET @HorasOrdinariasTmp = FLOOR(@HorasOrdinariasTmp);

                SET @HorasOrdinarias += @HorasOrdinariasTmp;
                SET @SalarioBruto += @HorasOrdinariasTmp * @SalarioHora;

                IF @HorasOrdinariasTmp > 0
                BEGIN
                    INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, Horas, IdSemana, IdMes)
                    VALUES (@IdEmpleado, 1, CAST(@Salida AS DATE), @HorasOrdinariasTmp * @SalarioHora, @HorasOrdinariasTmp, @IdSemana, @IdMes);
                END

                IF @Salida > @FechaHoraFin
                BEGIN
                    DECLARE @HorasExtra DECIMAL(10,2) = FLOOR(DATEDIFF(MINUTE, @FechaHoraFin, @Salida) / 60.0);
                    IF @HorasExtra > 0
                    BEGIN
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
                END

                FETCH NEXT FROM AsisCursor INTO @IdAsistencia, @Entrada, @Salida;
            END
            CLOSE AsisCursor;
            DEALLOCATE AsisCursor;

            -- Deducciones
            DECLARE @SemanasMes INT = (SELECT COUNT(*) FROM dbo.Semana S WHERE S.FechaFin BETWEEN (SELECT FechaInicio FROM dbo.Mes WHERE Id = @IdMes) AND (SELECT FechaFin FROM dbo.Mes WHERE Id = @IdMes));

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
                IF @Porcentaje IS NOT NULL
                BEGIN
                    DECLARE @Monto DECIMAL(10,2) = ROUND(@SalarioBruto * @Porcentaje, 2);
                    SET @TotalDeducciones += @Monto;
                    INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, IdSemana, IdMes)
                    VALUES (@IdEmpleado, @IdTipoDeduccion, @FechaFinSemana, -@Monto, @IdSemana, @IdMes);
                END
                FETCH NEXT FROM DedCursor INTO @IdTipoDeduccion, @Porcentaje;
            END
            CLOSE DedCursor;
            DEALLOCATE DedCursor;

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
                IF @MontoFijo IS NOT NULL AND @SemanasMes > 0
                BEGIN
                    DECLARE @MontoSemanal DECIMAL(10,2) = ROUND(@MontoFijo / @SemanasMes, 2);
                    SET @TotalDeducciones += @MontoSemanal;
                    INSERT INTO dbo.MovimientoPlanilla (IdEmpleado, IdTipoMovimiento, Fecha, Monto, IdSemana, IdMes)
                    VALUES (@IdEmpleado, @IdTipoDeduccion, @FechaFinSemana, -@MontoSemanal, @IdSemana, @IdMes);
                END
                FETCH NEXT FROM FixCursor INTO @IdTipoDeduccion, @MontoFijo;
            END
            CLOSE FixCursor;
            DEALLOCATE FixCursor;

            -- Actualizar encabezado
            SET @SalarioNeto = @SalarioBruto - @TotalDeducciones;
            UPDATE dbo.PlanillaSemEmpleado
            SET SalarioBruto = @SalarioBruto, TotalDeducciones = @TotalDeducciones, SalarioNeto = @SalarioNeto,
                HorasOrdinarias = @HorasOrdinarias, HorasExtraNormales = @HorasExtraNormales, HorasExtraDobles = @HorasExtraDobles
            WHERE IdEmpleado = @IdEmpleado AND IdSemana = @IdSemana;

            COMMIT;
            FETCH NEXT FROM EmpleadoCursor INTO @IdEmpleado;
        END
        CLOSE EmpleadoCursor;
        DEALLOCATE EmpleadoCursor;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        INSERT INTO dbo.DBError (UserName, Number, State, Severity, Line, ProcedureName, Message, DateTime)
        VALUES (SYSTEM_USER, ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        THROW;
    END CATCH
END
