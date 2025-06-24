USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CargarOperacionDesdeXML
(
    @inXmlData XML,
    @outResultCode INT OUTPUT,
    @inPostInIP NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DatosOperacion TABLE (
            TipoDato NVARCHAR(50),
            FechaOperacion DATE,
            ValorTipoDocumento NVARCHAR(50),
            IdTipoDeduccion INT,
            Monto DECIMAL(18,2),
            IdTipoJornada INT,
            HoraEntrada DATETIME,
            HoraSalida DATETIME,
            Nombre NVARCHAR(255),
            IdTipoDocumento INT,
            IdDepartamento INT,
            NombrePuesto NVARCHAR(255),
            Usuario NVARCHAR(255),
            Password NVARCHAR(255)
        );

        -- Asociación deducción
        INSERT INTO @DatosOperacion (
            TipoDato, FechaOperacion, ValorTipoDocumento, IdTipoDeduccion, Monto,
            IdTipoJornada, HoraEntrada, HoraSalida, Nombre, IdTipoDocumento,
            IdDepartamento, NombrePuesto, Usuario, Password
        )
        SELECT 
            'asociaciondeduccion',
            O.value('@Fecha', 'DATE'),
            D.value('@ValorTipoDocumento', 'NVARCHAR(50)'),
            D.value('@IdTipoDeduccion', 'INT'),
            D.value('@Monto', 'DECIMAL(18,2)'),
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
        FROM @inXmlData.nodes('/Operacion/FechaOperacion') AS T(O)
        CROSS APPLY O.nodes('AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS D(D);

        -- Desasociación deducción
        INSERT INTO @DatosOperacion (
            TipoDato, FechaOperacion, ValorTipoDocumento, IdTipoDeduccion, Monto,
            IdTipoJornada, HoraEntrada, HoraSalida, Nombre, IdTipoDocumento,
            IdDepartamento, NombrePuesto, Usuario, Password
        )
        SELECT 
            'desasociaciondeduccion',
            O.value('@Fecha', 'DATE'),
            D.value('@ValorTipoDocumento', 'NVARCHAR(50)'),
            D.value('@IdTipoDeduccion', 'INT'),
            NULL,
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
        FROM @inXmlData.nodes('/Operacion/FechaOperacion') AS T(O)
        CROSS APPLY O.nodes('DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS D(D);

        -- Jornada próxima semana
        INSERT INTO @DatosOperacion (
            TipoDato, FechaOperacion, ValorTipoDocumento, IdTipoDeduccion, Monto,
            IdTipoJornada, HoraEntrada, HoraSalida, Nombre, IdTipoDocumento,
            IdDepartamento, NombrePuesto, Usuario, Password
        )
        SELECT 
            'jornadaprosemanal',
            O.value('@Fecha', 'DATE'),
            J.value('@ValorTipoDocumento', 'NVARCHAR(50)'),
            NULL,
            NULL,
            J.value('@IdTipoJornada', 'INT'),
            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
        FROM @inXmlData.nodes('/Operacion/FechaOperacion') AS T(O)
        CROSS APPLY O.nodes('JornadasProximaSemana/TipoJornadaProximaSemana') AS J(J);

        -- Marca asistencia
        INSERT INTO @DatosOperacion (
            TipoDato, FechaOperacion, ValorTipoDocumento, IdTipoDeduccion, Monto,
            IdTipoJornada, HoraEntrada, HoraSalida, Nombre, IdTipoDocumento,
            IdDepartamento, NombrePuesto, Usuario, Password
        )
        SELECT 
            'marcaje',
            O.value('@Fecha', 'DATE'),
            M.value('@ValorTipoDocumento', 'NVARCHAR(50)'),
            NULL,
            NULL,
            NULL,
            M.value('@HoraEntrada', 'DATETIME'),
            M.value('@HoraSalida', 'DATETIME'),
            NULL, NULL, NULL, NULL, NULL, NULL
        FROM @inXmlData.nodes('/Operacion/FechaOperacion') AS T(O)
        CROSS APPLY O.nodes('MarcasAsistencia/MarcaDeAsistencia') AS M(M);

        -- Nuevo empleado
        INSERT INTO @DatosOperacion (
            TipoDato, FechaOperacion, ValorTipoDocumento, IdTipoDeduccion, Monto,
            IdTipoJornada, HoraEntrada, HoraSalida, Nombre, IdTipoDocumento,
            IdDepartamento, NombrePuesto, Usuario, Password
        )
        SELECT 
            'nuevoempleado',
            O.value('@Fecha', 'DATE'),
            E.value('@ValorTipoDocumento', 'NVARCHAR(50)'),
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            E.value('@Nombre', 'NVARCHAR(255)'),
            E.value('@IdTipoDocumento', 'INT'),
            E.value('@IdDepartamento', 'INT'),
            E.value('@NombrePuesto', 'NVARCHAR(255)'),
            E.value('@Usuario', 'NVARCHAR(255)'),
            E.value('@Password', 'NVARCHAR(255)')
        FROM @inXmlData.nodes('/Operacion/FechaOperacion') AS T(O)
        CROSS APPLY O.nodes('NuevosEmpleados/NuevoEmpleado') AS E(E);

		-- Asistencia
		INSERT INTO dbo.Asistencia (IdEmpleado, FechaEntrada, FechaSalida)
		SELECT E.Id, DO.HoraEntrada, DO.HoraSalida
		FROM @DatosOperacion DO
		INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		WHERE DO.TipoDato = 'marcaje'
		AND NOT EXISTS (
			SELECT 1 FROM dbo.Asistencia A 
			WHERE A.IdEmpleado = E.Id AND A.FechaEntrada = DO.HoraEntrada AND A.FechaSalida = DO.HoraSalida
		);

		-- Bitácora para asistencia
		INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, FechaHora, IP, Parametros, Antes, Despues)
		SELECT 
			E.IdUsuario, 14, DO.FechaOperacion, @inPostInIP,
			CONCAT('HoraEntrada=', CONVERT(varchar, DO.HoraEntrada), ', HoraSalida=', CONVERT(varchar, DO.HoraSalida)),
			'',
			CONCAT('IdEmpleado=', E.Id, ', FechaEntrada=', CONVERT(varchar, DO.HoraEntrada), ', FechaSalida=', CONVERT(varchar, DO.HoraSalida))
		FROM @DatosOperacion DO
		INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		WHERE DO.TipoDato = 'marcaje';

		-- Asociación deducción
		INSERT INTO dbo.DeduccionEmpleado (IdEmpleado, IdTipoDeduccion, ValorFijo, FechaAsociacion)
		SELECT DISTINCT E.Id, DO.IdTipoDeduccion, DO.Monto, DO.FechaOperacion
		FROM @DatosOperacion DO
		INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		WHERE DO.TipoDato = 'asociaciondeduccion'
		AND NOT EXISTS (
			SELECT 1 FROM dbo.DeduccionEmpleado DE
			WHERE DE.IdEmpleado = E.Id AND DE.IdTipoDeduccion = DO.IdTipoDeduccion AND DE.FechaAsociacion = DO.FechaOperacion
		);

		-- Bitácora para asociación deducción
		INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, FechaHora, IP, Parametros, Antes, Despues)
		SELECT 
			E.IdUsuario, 8, DO.FechaOperacion, @inPostInIP,
			CONCAT('IdTipoDeduccion=', DO.IdTipoDeduccion, ', Monto=', DO.Monto),
			'',
			CONCAT('IdEmpleado=', E.Id, ', IdTipoDeduccion=', DO.IdTipoDeduccion, ', ValorFijo=', DO.Monto)
		FROM @DatosOperacion DO
		INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		WHERE DO.TipoDato = 'asociaciondeduccion';

		-- Desasociación deducción (no se inserta, se elimina, no necesita EXISTS pero se mantiene el control)
		DELETE DE
		FROM dbo.DeduccionEmpleado DE
		INNER JOIN dbo.Empleado E ON DE.IdEmpleado = E.Id
		INNER JOIN @DatosOperacion DO ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		WHERE DO.TipoDato = 'desasociaciondeduccion'
		AND DE.IdTipoDeduccion = DO.IdTipoDeduccion;

		-- Bitácora para desasociación deducción
		INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, FechaHora, IP, Parametros, Antes, Despues)
		SELECT 
			E.IdUsuario, 9, DO.FechaOperacion, @inPostInIP,
			CONCAT('IdTipoDeduccion=', DO.IdTipoDeduccion),
			CONCAT('IdEmpleado=', E.Id, ', IdTipoDeduccion=', DO.IdTipoDeduccion),
			''
		FROM @DatosOperacion DO
		INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		WHERE DO.TipoDato = 'desasociaciondeduccion';

		-- Jornada por semana
		INSERT INTO dbo.JornadaPorSemana (IdEmpleado, IdSemana, IdTipoJornada)
		SELECT E.Id, S.Id, DO.IdTipoJornada
		FROM @DatosOperacion DO
		INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		INNER JOIN dbo.Semana S ON DO.FechaOperacion BETWEEN S.FechaInicio AND S.FechaFin
		WHERE DO.TipoDato = 'jornadaprosemanal'
		AND NOT EXISTS (
			SELECT 1 FROM dbo.JornadaPorSemana JPS 
			WHERE JPS.IdEmpleado = E.Id AND JPS.IdSemana = S.Id AND JPS.IdTipoJornada = DO.IdTipoJornada
		);

		-- Bitácora para jornada
		INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, FechaHora, IP, Parametros, Antes, Despues)
		SELECT 
			E.IdUsuario, 15, DO.FechaOperacion, @inPostInIP,
			CONCAT('IdSemana=', S.Id, ', IdTipoJornada=', DO.IdTipoJornada),
			'',
			CONCAT('IdEmpleado=', E.Id, ', IdSemana=', S.Id, ', IdTipoJornada=', DO.IdTipoJornada)
		FROM @DatosOperacion DO
		INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
		INNER JOIN dbo.Semana S ON DO.FechaOperacion BETWEEN S.FechaInicio AND S.FechaFin
		WHERE DO.TipoDato = 'jornadaprosemanal';

		-- Procesar nuevos empleados
DECLARE @NuevoIdUsuario INT;

DECLARE emp_cursor CURSOR FOR 
SELECT DO.Nombre, DO.ValorTipoDocumento, DO.IdTipoDocumento, DO.IdDepartamento,
       DO.NombrePuesto, DO.Usuario, DO.Password, DO.FechaOperacion
FROM @DatosOperacion DO
WHERE DO.TipoDato = 'nuevoempleado'
AND NOT EXISTS (
    SELECT 1 FROM dbo.Empleado E WHERE E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
);

DECLARE @Nombre NVARCHAR(255),
        @ValorTipoDocumento NVARCHAR(50),
        @IdTipoDocumento INT,
        @IdDepartamento INT,
        @NombrePuesto NVARCHAR(255),
        @Usuario NVARCHAR(255),
        @Password NVARCHAR(255),
        @FechaOperacion DATE;

OPEN emp_cursor;
FETCH NEXT FROM emp_cursor INTO @Nombre, @ValorTipoDocumento, @IdTipoDocumento, @IdDepartamento,
                               @NombrePuesto, @Usuario, @Password, @FechaOperacion;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Calcular nuevo ID usuario
    SELECT @NuevoIdUsuario = ISNULL(MAX(Id), 0) + 1 FROM dbo.Usuario;

    -- Insertar usuario
    INSERT INTO dbo.Usuario (Id, Username, Password, TipoUsuario)
    VALUES (@NuevoIdUsuario, @Usuario, @Password, 2);

    -- Insertar empleado
    INSERT INTO dbo.Empleado (IdPuesto, IdDepartamento, IdTipoIdentificacion, ValorDocumentoIdentidad, Nombre, FechaNacimiento, IdUsuario, EsActivo)
    SELECT P.Id, @IdDepartamento, @IdTipoDocumento, @ValorTipoDocumento, @Nombre, CAST(@FechaOperacion AS DATETIME), @NuevoIdUsuario, 1
    FROM dbo.Puesto P
    WHERE P.Nombre = @NombrePuesto;

    -- Bitácora
    INSERT INTO dbo.BitacoraEvento (IdUsuario, IdTipoEvento, FechaHora, IP, Parametros, Antes, Despues)
    VALUES (
        @NuevoIdUsuario, 5, @FechaOperacion, @inPostInIP,
        CONCAT('Nombre=', @Nombre, ', Usuario=', @Usuario),
        '',
        CONCAT('Nombre=', @Nombre, ', ValorDocumentoIdentidad=', @ValorTipoDocumento)
    );

    FETCH NEXT FROM emp_cursor INTO @Nombre, @ValorTipoDocumento, @IdTipoDocumento, @IdDepartamento,
                                   @NombrePuesto, @Usuario, @Password, @FechaOperacion;
END;

CLOSE emp_cursor;
DEALLOCATE emp_cursor;




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

    SET NOCOUNT OFF;
END;
GO
