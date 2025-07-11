USE [BDTP31]
GO
/****** Object:  StoredProcedure [dbo].[sp_CargarEmpleadosDesdeXML]    Script Date: 17/6/2025 20:17:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_CargarEmpleadosDesdeXML]
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
        -- Tabla variable con campos y comentarios
        -- ========================================
        DECLARE @DatosTabla TABLE (
            TipoDato NVARCHAR(50),         -- empleado, usuario, movimiento, error
            Campo1 NVARCHAR(255),          -- Username
            Campo2 NVARCHAR(255),          -- Password (usuario) / SaldoVacaciones (empleado)
            Campo3 NVARCHAR(255),          -- Id
            Campo4 NVARCHAR(255),          -- TipoAccion (movimientos)
            Campo5 NVARCHAR(255),          -- ValorDocumentoIdentidad
            Campo6 NVARCHAR(255),          -- FechaContratacion
            Campo7 NVARCHAR(255),          -- SaldoVacaciones
            Campo8 NVARCHAR(255),          -- IdTipoMovimiento
            Campo9 NVARCHAR(255),          -- Monto
            Campo10 NVARCHAR(255),         -- PostByUser
            Campo11 NVARCHAR(255),         -- NombrePuesto
            Campo12 NVARCHAR(255),         -- PostInIP
            Campo13 NVARCHAR(255),         -- PostTime
            Campo14 NVARCHAR(255),         -- Fecha (movimiento)
            Campo15 NVARCHAR(255),         -- Descripción (error)
            Campo16 NVARCHAR(255),         -- IdDepartamento
            Campo17 NVARCHAR(255),         -- IdTipoIdentificacion
            Campo18 NVARCHAR(255),         -- EsActivo
            Campo19 NVARCHAR(255),          -- TipoUsuario
			Campo20 NVARCHAR(255),			--Nombre
			Campo21 NVARCHAR(255),			--IdUsuario
			Campo22 NVARCHAR(255)			--Codigo
        );

        -- ========================================
        -- Cargar datos XML a tabla variable
        -- ========================================
        INSERT INTO @DatosTabla (
            TipoDato,
            Campo1,
            Campo2,
            Campo3,
            Campo4,
            Campo5,
            Campo6,
            Campo7,
            Campo8,
            Campo9,
            Campo10,
            Campo11,
            Campo12,
            Campo13,
            Campo14,
            Campo15,
            Campo16,
            Campo17,
            Campo18,
            Campo19,
			Campo20,
			Campo21,
			Campo22
        )
        SELECT
            LOWER(X.value('local-name(.)', 'NVARCHAR(50)')) AS TipoDato, 
			X.value('@Username', 'NVARCHAR(255)'),      -- Campo1 (Username)
			X.value('@Password', 'NVARCHAR(255)'),      -- Campo2 (Password)
			X.value('@Id', 'NVARCHAR(255)'),            -- Campo3 (Id)
			X.value('@TipoAccion', 'NVARCHAR(255)'),    -- Campo4
			X.value('@ValorDocumento', 'NVARCHAR(255)'),-- Campo5
			X.value('@FechaNacimiento', 'NVARCHAR(255)'), -- Campo6
			X.value('@SaldoVacaciones', 'NVARCHAR(255)'), -- Campo7
			X.value('@IdTipoMovimiento', 'NVARCHAR(255)'), -- Campo8
			X.value('@Monto', 'NVARCHAR(255)'),            -- Campo9
			X.value('@PostByUser', 'NVARCHAR(255)'),       -- Campo10
			X.value('@NombrePuesto', 'NVARCHAR(255)'),     -- Campo11
			X.value('@PostInIP', 'NVARCHAR(255)'),         -- Campo12
			X.value('@PostTime', 'NVARCHAR(255)'),         -- Campo13
			X.value('@Fecha', 'NVARCHAR(255)'),            -- Campo14
			X.value('@Descripcion', 'NVARCHAR(255)'),      -- Campo15
			X.value('@IdDepartamento', 'NVARCHAR(255)'),   -- Campo16
			X.value('@IdTipoDocumento', 'NVARCHAR(255)'),  -- Campo17
			X.value('@Activo', 'NVARCHAR(255)'),           -- Campo18
			X.value('@Tipo', 'NVARCHAR(255)'),              -- Campo19 (TipoUsuario)
			X.value('@Nombre', 'NVARCHAR(255)'),				-- Campo20 (nombre)
			X.value('@IdUsuario', 'NVARCHAR(255)'),			-- Campo21 (IdUsuario)
			X.value('@Codigo', 'NVARCHAR(255)')      -- Campo22 Codigo

        FROM @inXmlData.nodes('/Datos/*/*') AS T(X);

        -- ========================================
        -- Insertar usuarios
        -- ========================================
        INSERT INTO dbo.Usuario (
            Id,
            Username,
            Password,
            TipoUsuario,
            PostBy,
            PostInIP,
            PostTime
        )
        SELECT
            CAST(DT.Campo3 AS INT),
            DT.Campo1,
            DT.Campo2,
            CAST(DT.Campo19 AS INT),
            DT.Campo10,
            DT.Campo12,
            CAST(DT.Campo13 AS DATETIME)
        FROM @DatosTabla DT
        WHERE DT.TipoDato = 'usuario'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Usuario U WHERE U.Id = CAST(DT.Campo3 AS INT)
        );

        -- ========================================
        -- Insertar empleados
        -- ========================================
        INSERT INTO dbo.Empleado (
			IdPuesto,
			IdDepartamento,
			IdTipoIdentificacion,
			ValorDocumentoIdentidad,
			Nombre,
			FechaNacimiento,
			IdUsuario,
			EsActivo,
			PostBy,
			PostInIP,
			PostTime
		)
		SELECT
			P.Id,  
			CAST(DT.Campo16 AS INT),
			CAST(DT.Campo17 AS INT),
			DT.Campo5,
			DT.Campo20,
			CAST(DT.Campo6 AS DATE),
			CAST(DT.Campo21 AS INT),
			CAST(DT.Campo18 AS BIT),
			DT.Campo10,
			DT.Campo12,
			CAST(DT.Campo13 AS DATETIME)
		FROM @DatosTabla DT
		INNER JOIN dbo.Puesto P ON P.Nombre = DT.Campo11
		WHERE DT.TipoDato = 'empleado'
		AND NOT EXISTS (
			SELECT 1 FROM dbo.Empleado E WHERE E.ValorDocumentoIdentidad = DT.Campo5
		);

        -- ========================================
        -- Insertar movimientos iniciales (opcional)
        -- ========================================
        INSERT INTO dbo.MovimientoPlanilla (
            IdEmpleado,
            IdTipoMovimiento,
            Fecha,
            Monto,
            Horas,
            IdSemana,
            IdMes,
            PostBy,
            PostInIP,
            PostTime
        )
        SELECT
            e.Id,
            CAST(DT.Campo8 AS INT),
            CAST(DT.Campo14 AS DATE),
            CAST(DT.Campo9 AS DECIMAL(10,2)),
            NULL,
            NULL,
            NULL,
            DT.Campo10,
            DT.Campo12,
            CAST(DT.Campo13 AS DATETIME)
        FROM @DatosTabla DT
        INNER JOIN dbo.Empleado e ON e.ValorDocumentoIdentidad = DT.Campo5
        WHERE DT.TipoDato = 'movimiento'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.MovimientoPlanilla MP
            WHERE MP.IdEmpleado = e.Id
            AND MP.IdTipoMovimiento = CAST(DT.Campo8 AS INT)
            AND MP.Fecha = CAST(DT.Campo14 AS DATE)
        );

        -- ========================================
        -- Insertar errores registrados
        -- ========================================
        INSERT INTO dbo.Error (
            Codigo,
            Descripcion
        )
        SELECT
            CAST(Campo22 AS INT),
            Campo15
        FROM @DatosTabla
        WHERE TipoDato = 'error'
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Error E WHERE E.Codigo = CAST(Campo22 AS INT)
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
