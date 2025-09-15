CREATE DATABASE TiendaManualidades;
GO

USE TiendaManualidades;
GO

-- Tabla para la materia prima (inventario)
CREATE TABLE MateriaPrima (
    ID_Prima INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Prima VARCHAR(100) NOT NULL,
    Descripcion_Prima VARCHAR(255),
    Cantidad_Unitaria DECIMAL(10, 2) NOT NULL DEFAULT 0,
    EsPaquete BIT NOT NULL DEFAULT 0,
    EsTextil BIT NOT NULL DEFAULT 0, -- Para medir en cm
    Precio_Unitario DECIMAL(10, 2) NOT NULL,
    Unidad_Medida VARCHAR(20) NOT NULL DEFAULT 'Unidad', -- Unidad, Centímetro, Gramo, etc.
    Stock_Minimo INT DEFAULT 5,
    Fecha_Creacion DATETIME DEFAULT GETDATE()
);

-- Tabla de clientes
CREATE TABLE Cliente (
    ID_Cliente INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Cliente VARCHAR(100) NOT NULL,
    Telefono_Cliente VARCHAR(20),
    Instagram_Cliente VARCHAR(50),
    Email_Cliente VARCHAR(100),
    Direccion VARCHAR(255),
    Fecha_Registro DATETIME DEFAULT GETDATE()
);

-- Tabla de productos finales
CREATE TABLE Producto (
    ID_Producto INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Producto VARCHAR(100) NOT NULL,
    Descripcion_Producto VARCHAR(255),
    Precio_Producto DECIMAL(10, 2) NOT NULL,
    Imagen_URL VARCHAR(255),
    Activo BIT DEFAULT 1,
    Fecha_Creacion DATETIME DEFAULT GETDATE()
);

-- Tabla de relación entre productos y materias primas
CREATE TABLE PrimaProducto (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ID_Prima INT NOT NULL,
    ID_Producto INT NOT NULL,
    Cantidad_Prima DECIMAL(10, 2) NOT NULL, -- Cantidad de materia prima usada
    FOREIGN KEY (ID_Prima) REFERENCES MateriaPrima(ID_Prima),
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto),
    UNIQUE (ID_Prima, ID_Producto)
);

-- Tabla de facturas
CREATE TABLE Factura (
    ID_Factura INT IDENTITY(1,1) PRIMARY KEY,
    ID_Cliente INT NOT NULL,
    Metodo_Pago VARCHAR(50) NOT NULL,
    Precio_Subtotal DECIMAL(10, 2) NOT NULL,
    Descuento DECIMAL(10, 2) DEFAULT 0,
    Precio_Total DECIMAL(10, 2) NOT NULL,
    Fecha_Compra DATETIME DEFAULT GETDATE(),
    Observaciones VARCHAR(255),
    FOREIGN KEY (ID_Cliente) REFERENCES Cliente(ID_Cliente)
);

-- Tabla de detalles de factura
CREATE TABLE DetalleFactura (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ID_Factura INT NOT NULL,
    ID_Producto INT NOT NULL,
    Cantidad_Producto INT NOT NULL,
    Precio_Unitario DECIMAL(10, 2) NOT NULL,
    Subtotal DECIMAL(10, 2) NOT NULL,
    Descripcion_Producto VARCHAR(255),
    FOREIGN KEY (ID_Factura) REFERENCES Factura(ID_Factura),
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID_Producto)
);

-- Tabla de movimientos (entradas de inventario)
CREATE TABLE Movimiento (
    ID_Movimiento INT IDENTITY(1,1) PRIMARY KEY,
    ID_Prima INT NOT NULL,
    Cantidad_Prima DECIMAL(10, 2) NOT NULL,
    Precio_Compra DECIMAL(10, 2) NOT NULL,
    Fecha_Movimiento DATETIME DEFAULT GETDATE(),
    Tipo_Movimiento VARCHAR(20) DEFAULT 'Entrada', -- Entrada, Ajuste, Baja
    Descripcion VARCHAR(255),
    FOREIGN KEY (ID_Prima) REFERENCES MateriaPrima(ID_Prima)
);