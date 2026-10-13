CREATE DATABASE BikeZ_DW;
GO

USE BikeZ_DW;
GO

-- 2. DIMENSION TIEMPO

CREATE TABLE dbo.DimTiempo (
    TiempoID INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL,
    Anio INT NOT NULL,
    Trimestre INT NOT NULL,
    Mes INT NOT NULL,
    NombreMes VARCHAR(20) NOT NULL,
    Dia INT NOT NULL,
    DiaSemana VARCHAR(20) NOT NULL,

    CONSTRAINT UQ_DimTiempo_Fecha
        UNIQUE (Fecha)
);
GO

-- 3. DIMENSION CLIENTE

CREATE TABLE dbo.DimCliente (
    ClienteKey INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    Nombre NVARCHAR(100) NULL,
    Apellido NVARCHAR(100) NULL,

    CONSTRAINT UQ_DimCliente_ClienteID
        UNIQUE (ClienteID)
);
GO

-- 4. DIMENSION PRODUCTO

CREATE TABLE dbo.DimProducto (
    ProductoKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT NOT NULL,
    ProductoName NVARCHAR(150) NOT NULL,
    Color NVARCHAR(50) NULL,
    Categoria NVARCHAR(100) NULL,

    CONSTRAINT UQ_DimProducto_ProductoID
        UNIQUE (ProductoID)
);
GO

-- 5. DIMENSION EMPLEADO / VENDEDOR

CREATE TABLE dbo.DimEmpleado (
    VendedorKey INT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoID INT NOT NULL,
    Cargo NVARCHAR(100) NULL,
    Genero NCHAR(1) NULL,
    EstadoCivil NCHAR(1) NULL,

    CONSTRAINT UQ_DimEmpleado_EmpleadoID
        UNIQUE (EmpleadoID)
);
GO

SET IDENTITY_INSERT dbo.DimEmpleado ON;

INSERT INTO dbo.DimEmpleado (
    VendedorKey,
    EmpleadoID,
    Cargo,
    Genero,
    EstadoCivil
)
VALUES (-1, -1, 'Sin vendedor asignado', NULL, NULL);

SET IDENTITY_INSERT dbo.DimEmpleado OFF;
GO

-- 6. DIMENSION TERRITORIO

CREATE TABLE dbo.DimTerritorio (
    TerritorioKey INT IDENTITY(1,1) PRIMARY KEY,
    TerritorioID INT NOT NULL,
    Territorio NVARCHAR(100) NOT NULL,
    Pais NVARCHAR(100) NULL,
    Grupo NVARCHAR(100) NULL,

    CONSTRAINT UQ_DimTerritorio_TerritorioID
        UNIQUE (TerritorioID)
);
GO

-- 7. TABLA DE HECHOS FACTVENTAS

CREATE TABLE dbo.FactVentas (

    VentaID INT NOT NULL,
    DetalleVentaID INT NOT NULL,

    FechaVentaID INT NOT NULL,
    FechaEnvioID INT NULL,
    ClienteKey INT NOT NULL,
    ProductoKey INT NOT NULL,
    VendedorKey INT NOT NULL,
    TerritorioKey INT NOT NULL,

    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(19,4) NOT NULL,
    MontoTotal DECIMAL(19,4) NOT NULL,

    CONSTRAINT PK_FactVentas
        PRIMARY KEY (VentaID, DetalleVentaID),

    CONSTRAINT FK_FactVentas_FechaVenta
        FOREIGN KEY (FechaVentaID)
        REFERENCES dbo.DimTiempo(TiempoID),

    CONSTRAINT FK_FactVentas_FechaEnvio
        FOREIGN KEY (FechaEnvioID)
        REFERENCES dbo.DimTiempo(TiempoID),

    CONSTRAINT FK_FactVentas_Cliente
        FOREIGN KEY (ClienteKey)
        REFERENCES dbo.DimCliente(ClienteKey),

    CONSTRAINT FK_FactVentas_Producto
        FOREIGN KEY (ProductoKey)
        REFERENCES dbo.DimProducto(ProductoKey),

    CONSTRAINT FK_FactVentas_Vendedor
        FOREIGN KEY (VendedorKey)
        REFERENCES dbo.DimEmpleado(VendedorKey),

    CONSTRAINT FK_FactVentas_Territorio
        FOREIGN KEY (TerritorioKey)
        REFERENCES dbo.DimTerritorio(TerritorioKey),

    CONSTRAINT CK_FactVentas_Cantidad
        CHECK (Cantidad > 0),

    CONSTRAINT CK_FactVentas_Precio
        CHECK (PrecioUnitario > 0),

    CONSTRAINT CK_FactVentas_Monto
        CHECK (MontoTotal >= 0)
);
GO
