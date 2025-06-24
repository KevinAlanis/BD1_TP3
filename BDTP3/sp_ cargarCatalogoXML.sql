USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CargarCatalogosDesdeXML
(
    @inXmlData XML,
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ========================================
        -- Declarar tabla variable para staging XML
        -- ========================================
        DECLARE @DatosTabla TABLE (
            TipoDato NVARCHAR(50),             -- tipoidentificacion, puesto, etc.
            Campo1 NVARCHAR(255),              -- Nombre
            Campo2 NVARCHAR(255),              -- HoraInicio o Fecha
            Campo3 NVARCHAR(255),              -- HoraFin
            Campo4 NVARCHAR(255),              -- Id
            Campo5 NVARCHAR(255),              -- Obligatorio
            Campo6 NVARCHAR(255),              -- Porcentual
            Campo7 NVARCHAR(255),              -- Valor (monto)
            Campo8 NVARCHAR(255),              -- PostBy
            Campo9 NVARCHAR(255),              -- PostInIP
            Campo10 NVARCHAR(255),             -- PostTime
            Campo11 NVARCHAR(255),             -- SalarioxHora
            Campo12 NVARCHAR(255),             -- Codigo (de error)
            Campo13 NVARCHAR(255),              -- Descripcion (de error)
			Campo14 NVARCHAR(255)				-- Fecha para feriados

        );

        -- ========================================
        -- Parsear datos desde el XML
        -- ========================================
        INSERT INTO @DatosTabla (
            TipoDato,
			Campo1, -- Nombre
			Campo2, -- HoraInicio
			Campo3, -- HoraFin
			Campo4, -- Id
			Campo5, -- Obligatorio
			Campo6, -- Porcentual
			Campo7, -- Valor
			Campo8, -- PostBy
			Campo9, -- PostInIP
			Campo10, -- PostTime
			Campo11, -- SalarioXHora
			Campo12, -- Codigo
			Campo13, -- Descripcion
			Campo14  -- Fecha
        )
        SELECT
            LOWER(X.value('local-name(.)', 'NVARCHAR(50)')) AS TipoDato,
			X.value('@Nombre', 'NVARCHAR(255)'),		-- Campo1
            X.value('@HoraInicio', 'NVARCHAR(255)'),     -- Campo2
			X.value('@HoraFin', 'NVARCHAR(255)'),        -- Campo3
			X.value('@Id', 'NVARCHAR(255)'),             -- Campo4
			X.value('@Obligatorio', 'NVARCHAR(255)'),    -- Campo5
			X.value('@Porcentual', 'NVARCHAR(255)'),     -- Campo6
			X.value('@Valor', 'NVARCHAR(255)'),          -- Campo7
			X.value('@PostByUser', 'NVARCHAR(255)'),     -- Campo8
			X.value('@PostInIP', 'NVARCHAR(255)'),       -- Campo9
			X.value('@PostTime', 'NVARCHAR(255)'),       -- Campo10
			X.value('@SalarioXHora', 'NVARCHAR(255)'),   -- Campo11
			X.value('@Codigo', 'NVARCHAR(255)'),         -- Campo12
			X.value('@Descripcion', 'NVARCHAR(255)'),    -- Campo13
			X.value('@Fecha', 'NVARCHAR(255)')           -- Campo14


        FROM @inXmlData.nodes('/Datos/*/*') AS T(X);

        -- ========================================
        -- Insertar datos en tablas físicas
        -- ========================================

        -- TipoIdentificacion
        INSERT INTO dbo.TipoIdentificacion (
			Id, 
			Nombre
		)
        SELECT
            CAST(Campo4 AS INT),
            DT.Campo1
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'tipodocuidentidad'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.TipoIdentificacion TI WHERE TI.Id = CAST(DT.Campo4 AS INT)
        );

        -- TipoJornada
        INSERT INTO dbo.TipoJornada (
			Id, 
			Nombre, 
			HoraInicio, 
			HoraFin
		)
        SELECT
            CAST(Campo4 AS INT),
            DT.Campo1,
            CAST(Campo2 AS TIME),
            CAST(Campo3 AS TIME)
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'tipodejornada'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.TipoJornada TJ WHERE TJ.Id = CAST(DT.Campo4 AS INT)
        );

        -- TipoMovimiento
        INSERT INTO dbo.TipoMovimiento (
			Id, 
			Nombre, 
			PostBy, 
			PostInIP, 
			PostTime
		)
        SELECT
            CAST(Campo4 AS INT),
            DT.Campo1,
            DT.Campo8,
            DT.Campo9,
            CAST(Campo10 AS DATETIME)
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'tipodemovimiento'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.TipoMovimiento TM WHERE TM.Id = CAST(DT.Campo4 AS INT)
        );

        -- TipoEvento
        INSERT INTO dbo.TipoEvento (
			Id, 
			Nombre
		)
        SELECT
            CAST(Campo4 AS INT),
            DT.Campo1
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'tipoevento'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.TipoEvento TE WHERE TE.Id = CAST(DT.Campo4 AS INT)
        );

        -- TipoDeduccion
        INSERT INTO dbo.TipoDeduccion (
			Id, 
			Nombre, 
			Obligatorio, 
			Porcentual, 
			Valor
		)
        SELECT
            CAST(Campo4 AS INT),
            DT.Campo1,
            DT.Campo5,
            DT.Campo6,
            CAST(Campo7 AS DECIMAL(10,5))
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'tipodededuccion'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.TipoDeduccion TD WHERE TD.Id = CAST(DT.Campo4 AS INT)
        );

        -- Departamento
        INSERT INTO dbo.Departamento (
			Id, 
			Nombre
		)
        SELECT
            CAST(Campo4 AS INT),
            DT.Campo1
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'departamento'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Departamento D WHERE D.Id = CAST(DT.Campo4 AS INT)
        );


        -- Puesto
		INSERT INTO dbo.Puesto (
			Nombre, 
			SalarioxHora, 
			PostBy, 
			PostInIP, 
			PostTime
		)
        SELECT
            DT.Campo1,
            CAST(DT.Campo11 AS DECIMAL(10,2)),
            DT.Campo10,
            DT.Campo12,
            CAST(DT.Campo13 AS DATETIME)
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'puesto'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Puesto P WHERE P.Nombre = DT.Campo1
        );


        -- Feriado
        INSERT INTO dbo.Feriado (
			Id, 
			Nombre, 
			Fecha, 
			PostBy, 
			PostInIP, 
			PostTime
			)
        SELECT
            CAST(Campo4 AS INT),
            DT.Campo1,
            CAST(Campo14 AS DATE),
            DT.Campo8,
            DT.Campo9,
            CAST(Campo10 AS DATETIME)
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'feriado'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Feriado F WHERE F.Id = CAST(DT.Campo4 AS INT)
        );

        -- Error
        INSERT INTO dbo.Error (
			Codigo, 
			Descripcion
		)
        SELECT
            CAST(Campo12 AS INT),
            DT.Campo13
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'error'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Error E WHERE E.Codigo = CAST(DT.Campo12 AS INT)
        );

        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        INSERT INTO dbo.DBError (
            UserName,
            Number,
            State,
            Severity,
            Line,
            ProcedureName,
            Message,
            DateTime
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
