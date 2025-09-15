USE TiendaManualidades;
GO

-- Trigger para verificar inventario suficiente antes de agregar un producto a la factura
CREATE TRIGGER tr_VerificarInventario
ON DetalleFactura
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @ID_Producto INT;
    DECLARE @Cantidad INT;
    DECLARE @ID_Factura INT;
    DECLARE @Precio_Unitario DECIMAL(10, 2);
    DECLARE @Descripcion VARCHAR(255);
    
    -- Obtener valores de la fila insertada
    SELECT 
        @ID_Producto = ID_Producto,
        @Cantidad = Cantidad_Producto,
        @ID_Factura = ID_Factura,
        @Precio_Unitario = Precio_Unitario,
        @Descripcion = Descripcion_Producto
    FROM inserted;
    
    -- Verificar si hay suficiente inventario para todos los componentes
    IF EXISTS (
        SELECT 1
        FROM PrimaProducto pp
        JOIN MateriaPrima mp ON pp.ID_Prima = mp.ID_Prima
        WHERE pp.ID_Producto = @ID_Producto
        AND (mp.Cantidad_Unitaria < (pp.Cantidad_Prima * @Cantidad))
    )
    BEGIN
        -- Mostrar qué materiales no tienen suficiente stock
        DECLARE @MensajeError VARCHAR(1000) = 'No hay suficiente inventario para los siguientes materiales: ';
        
        SELECT @MensajeError = @MensajeError + mp.Nombre_Prima + ' (Disponible: ' + 
                              CAST(mp.Cantidad_Unitaria AS VARCHAR) + ', Necesario: ' + 
                              CAST(pp.Cantidad_Prima * @Cantidad AS VARCHAR) + '), '
        FROM PrimaProducto pp
        JOIN MateriaPrima mp ON pp.ID_Prima = mp.ID_Prima
        WHERE pp.ID_Producto = @ID_Producto
        AND (mp.Cantidad_Unitaria < (pp.Cantidad_Prima * @Cantidad));
        
        RAISERROR(@MensajeError, 16, 1);
        RETURN;
    END
    
    -- Si hay suficiente inventario, insertar el detalle de la factura
    INSERT INTO DetalleFactura (ID_Factura, ID_Producto, Cantidad_Producto, Precio_Unitario, Subtotal, Descripcion_Producto)
    VALUES (@ID_Factura, @ID_Producto, @Cantidad, @Precio_Unitario, @Precio_Unitario * @Cantidad, @Descripcion);
    
    -- Actualizar los totales en la factura
    UPDATE Factura
    SET Precio_Subtotal = Precio_Subtotal + (@Precio_Unitario * @Cantidad),
        Precio_Total = (Precio_Subtotal + (@Precio_Unitario * @Cantidad)) - Descuento
    WHERE ID_Factura = @ID_Factura;
    
    -- Descontar del inventario
    UPDATE MateriaPrima
    SET Cantidad_Unitaria = Cantidad_Unitaria - (pp.Cantidad_Prima * @Cantidad)
    FROM MateriaPrima mp
    JOIN PrimaProducto pp ON mp.ID_Prima = pp.ID_Prima
    WHERE pp.ID_Producto = @ID_Producto;
END;
GO

-- Trigger para actualizar el precio total de la factura cuando se modifica el descuento
CREATE TRIGGER tr_ActualizarTotalFactura
ON Factura
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Descuento)
    BEGIN
        UPDATE f 
        SET Precio_Total = f.Precio_Subtotal - f.Descuento
        FROM Factura f
        INNER JOIN inserted i ON f.ID_Factura = i.ID_Factura;
    END
END;
GO