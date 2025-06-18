USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CargarOperacionDesdeXML
(
    @inXmlData XML,
    @outResultCode INT OUTPUT
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
        CROSS APPLY O.nodes('AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') AS X(D);

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
        CROSS APPLY O.nodes('DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') AS X(D);

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
        CROSS APPLY O.nodes('JornadasProximaSemana/TipoJornadaProximaSemana') AS X(J);

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
        CROSS APPLY O.nodes('MarcasAsistencia/MarcaDeAsistencia') AS X(M);

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
        CROSS APPLY O.nodes('NuevosEmpleados/NuevoEmpleado') AS X(E);

        -- Marca asistencia
        INSERT INTO dbo.MarcaAsistencia (IdEmpleado, Fecha, HoraEntrada, HoraSalida)
        SELECT E.Id, DO.FechaOperacion, DO.HoraEntrada, DO.HoraSalida
        FROM @DatosOperacion DO
        INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
        WHERE DO.TipoDato = 'marcaje';

        -- Asociación deducción
        INSERT INTO dbo.DeduccionEmpleado (IdEmpleado, IdTipoDeduccion, ValorFijo)
        SELECT E.Id, DO.IdTipoDeduccion, DO.Monto
        FROM @DatosOperacion DO
        INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
        WHERE DO.TipoDato = 'asociaciondeduccion';

        -- Desasociación deducción
        DELETE DE
        FROM dbo.DeduccionEmpleado DE
        INNER JOIN dbo.Empleado E ON DE.IdEmpleado = E.Id
        INNER JOIN @DatosOperacion DO ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
        WHERE DO.TipoDato = 'desasociaciondeduccion'
          AND DE.IdTipoDeduccion = DO.IdTipoDeduccion;

        -- JornadaPorSemana
        INSERT INTO dbo.JornadaPorSemana (IdEmpleado, IdSemana, IdTipoJornada)
        SELECT E.Id, NULL, DO.IdTipoJornada
        FROM @DatosOperacion DO
        INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = DO.ValorTipoDocumento
        WHERE DO.TipoDato = 'jornadaprosemanal';

        -- Usuario nuevo
        INSERT INTO dbo.Usuario (Username, Password, TipoUsuario)
        SELECT DO.Usuario, DO.Password, 2
        FROM @DatosOperacion DO
        WHERE DO.TipoDato = 'nuevoempleado'
          AND NOT EXISTS (SELECT 1 FROM dbo.Usuario U WHERE U.Username = DO.Usuario);

        -- Empleado nuevo
        INSERT INTO dbo.Empleado (IdPuesto, IdDepartamento, IdTipoIdentificacion, ValorDocumentoIdentidad, Nombre, FechaNacimiento, IdUsuario, EsActivo)
        SELECT P.Id, DO.IdDepartamento, DO.IdTipoDocumento, DO.ValorTipoDocumento, DO.Nombre, GETDATE(), U.Id, 1
        FROM @DatosOperacion DO
        INNER JOIN dbo.Puesto P ON P.Nombre = DO.NombrePuesto
        INNER JOIN dbo.Usuario U ON U.Username = DO.Usuario
        WHERE DO.TipoDato = 'nuevoempleado';

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
