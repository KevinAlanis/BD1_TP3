USE BDTP31;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BorrarEmpleado
(
    @inIdEmpleado INT,
    @outResultCode INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Empleado
        SET EsActivo = 0
        WHERE Id = @inIdEmpleado;

        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @outResultCode = ERROR_NUMBER();
    END CATCH;
END;
GO
