USE TiendaManualidades;
GO

-- Procedimiento para registrar una nueva entrada de materia prima
CREATE PROCEDURE sp_RegistrarEntradaMateriaPrima
    @ID_Prima INT,
    @Cantidad DECIMAL(10, 2),
    @Precio DECIMAL(10, 2),
    @Descripcion VARCHAR(255) = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Registrar el movimiento
        INSERT INTO Movimiento (ID_Prima, Cantidad_Prima, Precio_Compra, Descripcion)
        VALUES (@ID_Prima, @Cantidad, @Precio, @Descripcion);
        
        -- Actualizar el inventario
        UPDATE MateriaPrima
        SET Cantidad_Unitaria = Cantidad_Unitaria + @Cantidad,
            Precio_Unitario = CASE 
                              WHEN (Cantidad_Unitaria = 0) THEN @Precio 
                              ELSE (Precio_Unitario * Cantidad_Unitaria + @Precio * @Cantidad) / (Cantidad_Unitaria + @Cantidad)
                              END
        WHERE ID_Prima = @ID_Prima;
        
        COMMIT TRANSACTION;
        SELECT 'Entrada registrada correctamente' AS Resultado;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

-- Procedimiento para crear una nueva factura
CREATE PROCEDURE sp_CrearFactura
    @ID_Cliente INT,
    @Metodo_Pago VARCHAR(50),
    @Descuento DECIMAL(10, 2) = 0,
    @Observaciones VARCHAR(255) = NULL
AS
BEGIN
    DECLARE @ID_Factura INT;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Insertar la cabecera de la factura con valores temporales para los totales
        INSERT INTO Factura (ID_Cliente, Metodo_Pago, Precio_Subtotal, Descuento, Precio_Total, Observaciones)
        VALUES (@ID_Cliente, @Metodo_Pago, 0, @Descuento, 0, @Observaciones);
        
        -- Obtener el ID de la factura creada
        SET @ID_Factura = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        SELECT @ID_Factura AS ID_Factura, 'Factura creada correctamente' AS Resultado;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 0 AS ID_Factura, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO


-- Procedimiento para actualizar el inventario después de una venta
CREATE PROCEDURE sp_ActualizarInventarioPorVenta
    @ID_Producto INT,
    @Cantidad INT
AS
BEGIN
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Actualizar la cantidad de cada materia prima utilizada por el producto
        UPDATE MateriaPrima
        SET Cantidad_Unitaria = Cantidad_Unitaria - (pp.Cantidad_Prima * @Cantidad)
        FROM MateriaPrima mp
        INNER JOIN PrimaProducto pp ON mp.ID_Prima = pp.ID_Prima
        WHERE pp.ID_Producto = @ID_Producto;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
-- Procedimiento para agregar un producto a una factura
CREATE PROCEDURE sp_AgregarProductoFactura
    @ID_Factura INT,
    @ID_Producto INT,
    @Cantidad INT,
    @Descripcion_Producto VARCHAR(255) = NULL
AS
BEGIN
    DECLARE @Precio_Unitario DECIMAL(10, 2);
    DECLARE @Subtotal DECIMAL(10, 2);
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Obtener el precio del producto
        SELECT @Precio_Unitario = Precio_Producto 
        FROM Producto 
        WHERE ID_Producto = @ID_Producto;
        
        IF @Precio_Unitario IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'El producto no existe' AS ErrorMessage;
            RETURN;
        END;
        
        -- Calcular subtotal
        SET @Subtotal = @Precio_Unitario * @Cantidad;
        
        -- Insertar el detalle de la factura
        INSERT INTO DetalleFactura (ID_Factura, ID_Producto, Cantidad_Producto, Precio_Unitario, Subtotal, Descripcion_Producto)
        VALUES (@ID_Factura, @ID_Producto, @Cantidad, @Precio_Unitario, @Subtotal, @Descripcion_Producto);
        
        -- Actualizar los totales en la factura
        UPDATE Factura
        SET Precio_Subtotal = Precio_Subtotal + @Subtotal,
            Precio_Total = (Precio_Subtotal + @Subtotal) - Descuento
        WHERE ID_Factura = @ID_Factura;
        
        -- Llamar al procedimiento que actualiza el inventario
        EXEC sp_ActualizarInventarioPorVenta @ID_Producto, @Cantidad;
        
        COMMIT TRANSACTION;
        SELECT 'Producto agregado correctamente' AS Resultado;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END;
GO

-- Procedimiento para generar balance mensual
CREATE PROCEDURE sp_GenerarBalanceMensual
    @Mes INT,
    @Anio INT
AS
BEGIN
    DECLARE @FechaInicio DATE = DATEFROMPARTS(@Anio, @Mes, 1);
    DECLARE @FechaFin DATE = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FechaInicio));
    
    -- Total de ventas
    DECLARE @TotalVentas DECIMAL(10, 2);
    SELECT @TotalVentas = SUM(Precio_Total) 
    FROM Factura 
    WHERE Fecha_Compra BETWEEN @FechaInicio AND @FechaFin;
    
    -- Total de compras de materiales
    DECLARE @TotalCompras DECIMAL(10, 2);
    SELECT @TotalCompras = SUM(Precio_Compra * Cantidad_Prima) 
    FROM Movimiento 
    WHERE Fecha_Movimiento BETWEEN @FechaInicio AND @FechaFin
    AND Tipo_Movimiento = 'Entrada';
    
    -- Ganancia
    DECLARE @Ganancia DECIMAL(10, 2) = ISNULL(@TotalVentas, 0) - ISNULL(@TotalCompras, 0);
    
    -- Resultado
    SELECT 
        @Mes AS Mes,
        @Anio AS Año,
        ISNULL(@TotalVentas, 0) AS TotalVentas,
        ISNULL(@TotalCompras, 0) AS TotalCompras,
        @Ganancia AS Ganancia;
    
    -- Detalle de productos más vendidos
    SELECT TOP 10
        p.ID_Producto,
        p.Nombre_Producto,
        SUM(df.Cantidad_Producto) AS Cantidad_Vendida,
        SUM(df.Subtotal) AS Total_Ventas
    FROM DetalleFactura df
    INNER JOIN Producto p ON df.ID_Producto = p.ID_Producto
    INNER JOIN Factura f ON df.ID_Factura = f.ID_Factura
    WHERE f.Fecha_Compra BETWEEN @FechaInicio AND @FechaFin
    GROUP BY p.ID_Producto, p.Nombre_Producto
    ORDER BY Cantidad_Vendida DESC;
    
    -- Materiales con bajo stock
    SELECT
        ID_Prima,
        Nombre_Prima,
        Cantidad_Unitaria,
        Stock_Minimo
    FROM MateriaPrima
    WHERE Cantidad_Unitaria <= Stock_Minimo
    ORDER BY Cantidad_Unitaria;
END;
GO