/*
    PROYECTO BIKEZ - INTELIGENCIA DE NEGOCIOS
    EXPLORACION Y VALIDACION DE DATOS

    Objetivo:
    Analizar las tablas Ventas y DetalleVentas de la base transaccional BikeZ para preparar la extraccion hacia FactVentas.

    Base de datos: BikeZ
    Herramienta: SQL Server Management Studio

    IMPORTANTE:
    Este script contiene solo consultas de lectura, no modifica ni elimina datos.
*/

USE [BikeZ];
GO

-- =========================================
-- 1. NUMERO DE FILAS REALES
-- =========================================

SELECT
    'Ventas' AS Tabla,
    COUNT_BIG(*) AS Registros
FROM dbo.Ventas

UNION ALL

SELECT
    'DetalleVentas',
    COUNT_BIG(*)
FROM dbo.DetalleVentas;
GO


-- =========================================
-- 2. COLUMNAS, TIPOS Y NULABILIDAD
-- =========================================

SELECT
    TABLE_NAME AS Tabla,
    ORDINAL_POSITION AS Posicion,
    COLUMN_NAME AS Columna,
    DATA_TYPE AS TipoDato,
    NUMERIC_PRECISION AS PrecisionNumerica,
    NUMERIC_SCALE AS EscalaNumerica,
    IS_NULLABLE AS PermiteNulos
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN ('Ventas', 'DetalleVentas')
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;
GO


-- =========================================
-- 3. IDENTIFICACION DE CLAVES PRIMARIAS
-- =========================================

SELECT
    t.name AS Tabla,
    i.name AS ClavePrimaria,
    c.name AS Columna,
    ic.key_ordinal AS OrdenColumna
FROM sys.tables AS t

INNER JOIN sys.indexes AS i
    ON i.object_id = t.object_id
    AND i.is_primary_key = 1

INNER JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id
    AND ic.index_id = i.index_id

INNER JOIN sys.columns AS c
    ON c.object_id = ic.object_id
    AND c.column_id = ic.column_id

WHERE t.name IN ('Ventas', 'DetalleVentas')
ORDER BY
    t.name,
    ic.key_ordinal;
GO


-- =========================================
-- 4. RELACIONES DECLARADAS ENTRE TABLAS
-- =========================================

SELECT
    fk.name AS Relacion,
    OBJECT_NAME(fkc.parent_object_id)
        AS TablaOrigen,
    COL_NAME(
        fkc.parent_object_id,
        fkc.parent_column_id
    ) AS ColumnaOrigen,
    OBJECT_NAME(fkc.referenced_object_id)
        AS TablaDestino,
    COL_NAME(
        fkc.referenced_object_id,
        fkc.referenced_column_id
    ) AS ColumnaDestino
FROM sys.foreign_keys AS fk

INNER JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id

WHERE OBJECT_NAME(fkc.parent_object_id)
        IN ('Ventas', 'DetalleVentas')
   OR OBJECT_NAME(fkc.referenced_object_id)
        IN ('Ventas', 'DetalleVentas')

ORDER BY
    TablaOrigen,
    Relacion;
GO


-- =========================================
-- 5. MUESTRA DE REGISTROS ORIGINALES
-- =========================================

SELECT TOP (20) *
FROM dbo.Ventas;

SELECT TOP (20) *
FROM dbo.DetalleVentas;
GO


-- =========================================
-- 6. VALIDACION DE INTEGRIDAD DE DETALLES
-- =========================================

-- Identificar detalles que no tienen
-- una venta asociada.

SELECT
    COUNT(*) AS DetallesSinVenta
FROM dbo.DetalleVentas AS D

LEFT JOIN dbo.Ventas AS V
    ON D.VentaID = V.VentaID

WHERE V.VentaID IS NULL;
GO


-- =========================================
-- 7. REVISION DE VALORES NULOS
-- =========================================

-- Verificar campos relevantes de Ventas.

SELECT
    COUNT(*) AS TotalVentas,

    SUM(
        CASE
            WHEN FechaEnvio IS NULL THEN 1
            ELSE 0
        END
    ) AS FechaEnvioNula,

    SUM(
        CASE
            WHEN VendedorID IS NULL THEN 1
            ELSE 0
        END
    ) AS VendedorNulo,

    SUM(
        CASE
            WHEN TerritorioID IS NULL THEN 1
            ELSE 0
        END
    ) AS TerritorioNulo

FROM dbo.Ventas;
GO


-- =========================================
-- 8. IDENTIFICACION DE DUPLICADOS
-- =========================================

-- Comprobar si existen identificadores
-- DetalleVentaID repetidos.

SELECT
    DetalleVentaID,
    COUNT(*) AS VecesRepetido
FROM dbo.DetalleVentas

GROUP BY DetalleVentaID

HAVING COUNT(*) > 1;
GO


-- =========================================
-- 9. VALIDACION DE CANTIDADES Y PRECIOS
-- =========================================

-- Identificar cantidades o precios no
-- positivos y posibles valores nulos.

SELECT
    COUNT(*) AS TotalDetalles,

    SUM(
        CASE
            WHEN Cantidad <= 0 THEN 1
            ELSE 0
        END
    ) AS CantidadesInvalidas,

    SUM(
        CASE
            WHEN PrecioUnitario <= 0 THEN 1
            ELSE 0
        END
    ) AS PreciosNoPositivos,

    SUM(
        CASE
            WHEN Cantidad IS NULL THEN 1
            ELSE 0
        END
    ) AS CantidadesNulas,

    SUM(
        CASE
            WHEN PrecioUnitario IS NULL THEN 1
            ELSE 0
        END
    ) AS PreciosNulos

FROM dbo.DetalleVentas;
GO


-- =========================================
-- 10. VALIDACION DE IMPORTES DE VENTA
-- =========================================

-- Calcular el importe mediante:
-- Cantidad * PrecioUnitario
-- Se conserva precision DECIMAL(19,4).

SELECT
    COUNT(*) AS TotalDetalles,

    SUM(
        CAST(
            Cantidad * PrecioUnitario
            AS DECIMAL(19,4)
        )
    ) AS ImporteTotal,

    MIN(
        CAST(
            Cantidad * PrecioUnitario
            AS DECIMAL(19,4)
        )
    ) AS ImporteMinimo,

    MAX(
        CAST(
            Cantidad * PrecioUnitario
            AS DECIMAL(19,4)
        )
    ) AS ImporteMaximo

FROM dbo.DetalleVentas;
GO


-- =========================================
-- 11. CONSULTA DE EXTRACCION PARA SSIS
-- =========================================

-- Relacionar Ventas y DetalleVentas.
-- Cada fila representa un detalle de venta.
--
-- Transformaciones:
-- 1. Convertir las fechas a DATE.
-- 2. Reemplazar vendedor NULL por -1.
-- 3. Calcular ImporteDetalle.
--
-- Esta consulta es la base del componente
-- Origen_Ventas_BikeZ en SSIS.

SELECT
    V.VentaID,
    D.DetalleVentaID,

    CAST(V.Fecha AS DATE) AS FechaVenta,
    CAST(V.FechaEnvio AS DATE) AS FechaEnvio,

    V.ClienteID,

    CASE
        WHEN V.VendedorID IS NULL THEN -1
        ELSE V.VendedorID
    END AS VendedorID_ETL,

    V.TerritorioID,
    D.ProductoID,
    D.Cantidad,
    D.PrecioUnitario,

    CAST(
        D.Cantidad * D.PrecioUnitario
        AS DECIMAL(19,4)
    ) AS ImporteDetalle

FROM dbo.Ventas AS V

INNER JOIN dbo.DetalleVentas AS D
    ON V.VentaID = D.VentaID;
GO


-- =========================================
-- 12. VALIDACION DE REGISTROS EXTRAIDOS
-- =========================================

-- Comprobar que la union mantiene
-- los detalles de venta originales.

SELECT
    COUNT(*) AS TotalRegistrosExtraidos
FROM dbo.Ventas AS V

INNER JOIN dbo.DetalleVentas AS D
    ON V.VentaID = D.VentaID;
GO
