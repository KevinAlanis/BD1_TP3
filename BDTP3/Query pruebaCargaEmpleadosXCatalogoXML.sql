DECLARE @xml XML;
DECLARE @resultCode INT;

-- Leer el XML como BLOB y convertirlo a XML
SELECT @xml = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\Users\kevin\Downloads\catalogos.xml', SINGLE_BLOB) AS x;

-- Ejecutar el SP de carga de empleados y usuarios
EXEC dbo.sp_CargarEmpleadosDesdeXML
    @inXmlData = @xml,
    @outResultCode = @resultCode OUTPUT;

-- Ver resultado
SELECT @resultCode AS CodigoResultado;
