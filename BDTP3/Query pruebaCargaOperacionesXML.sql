DECLARE @xml XML;
DECLARE @resultCode INT;

-- Cargar el XML desde archivo
SELECT @xml = CAST(BulkColumn AS XML)
FROM OPENROWSET(
    BULK 'C:\Users\kevin\Downloads\operacionFIN.xml',
    SINGLE_BLOB
) AS x;

-- Ejecutar el SP de carga
EXEC dbo.sp_CargarOperacionDesdeXML
    @inXmlData = @xml,
	@inPostInIP = '192.168.1.100',
    @outResultCode = @resultCode OUTPUT;

-- Mostrar resultado del SP
SELECT @resultCode AS CodigoResultado;

SELECT TOP 20 *
FROM dbo.DBError
ORDER BY DateTime DESC;

SELECT * FROM semana
SELECT * FROM Asistencia