/*
    PROYECTO BIKEZ - INTELIGENCIA DE NEGOCIOS 
    VALIDACION DE FACTVENTAS

    Objetivo:
    Validar que los registros extraidos desde BikeZ se hayan cargado correctamente en BikeZ_DW.dbo.FactVentas mediante SSIS.

    Bases de datos:
    - BikeZ: origen transaccional.
    - BikeZ_DW: Data Warehouse.

    Herramienta: SQL Server Management Studio.

    IMPORTANTE:
    Este script contiene solo consultas de lectura, no modifica ni elimina registros.

    Ejecutar despues de completar la carga ETL.
*/

USE [BikeZ_DW];
GO


-- =========================================
-- 1. CANTIDAD DE REGISTROS CARGADOS
-- =========================================

SELECT
    COUNT_BIG(*) AS TotalRegistros,
    COUNT(DISTINCT DetalleVentaID) AS DetallesUnicos
FROM dbo.FactVentas;
GO


-- =========================================
-- 2. IDENTIFICADORES DUPLICADOS
-- =========================================

-- Comprobar si existen detalles repetidos.

SELECT
    VentaID,
    DetalleVentaID,
    COUNT(*) AS VecesRepetido
FROM dbo.FactVentas
GROUP BY
    VentaID,
    DetalleVentaID
HAVING COUNT(*) > 1;
GO


-- =========================================
-- 3. VALIDACION DE MEDIDAS
-- =========================================

-- Comprobar registros, unidades, importes
-- y detalles sin vendedor asignado.

SELECT
    COUNT(*) AS TotalRegistros,

    COUNT(DISTINCT DetalleVentaID)
        AS DetallesUnicos,

    SUM(Cantidad)
        AS UnidadesVendidas,

    SUM(MontoTotal)
        AS ImporteTotal,

    SUM(
        CASE
            WHEN VendedorKey = -1 THEN 1
            ELSE 0
        END
    ) AS DetallesSinVendedor

FROM dbo.FactVentas;
GO


-- =========================================
-- 4. COMPARACION ORIGEN VS DESTINO
-- =========================================

-- Comparar registros, unidades e importes.
-- Las diferencias esperadas son cero.

WITH Origen AS (
    SELECT
        COUNT_BIG(*) AS Registros,
        SUM(CAST(D.Cantidad AS BIGINT))
            AS Unidades,
        SUM(
            CAST(
                D.Cantidad * D.PrecioUnitario
                AS DECIMAL(19,4)
            )
        ) AS Importe
    FROM BikeZ.dbo.DetalleVentas AS D
),
Destino AS (
    SELECT
        COUNT_BIG(*) AS Registros,
        SUM(CAST(Cantidad AS BIGINT))
            AS Unidades,
        SUM(MontoTotal) AS Importe
    FROM dbo.FactVentas
)
SELECT
    O.Registros AS RegistrosOrigen,
    D.Registros AS RegistrosDestino,
    O.Registros - D.Registros
        AS DiferenciaRegistros,

    O.Unidades AS UnidadesOrigen,
    D.Unidades AS UnidadesDestino,
    O.Unidades - D.Unidades
        AS DiferenciaUnidades,

    O.Importe AS ImporteOrigen,
    D.Importe AS ImporteDestino,
    O.Importe - D.Importe
        AS DiferenciaImporte

FROM Origen AS O
CROSS JOIN Destino AS D;
GO


-- =========================================
-- 5. VENDEDORES SIN ASIGNAR
-- =========================================

-- Comparar los detalles cuyo vendedor
-- original es NULL con los registros
-- asignados a VendedorKey = -1.

WITH Origen AS (
    SELECT
        COUNT_BIG(*) AS DetallesSinVendedorOrigen
    FROM BikeZ.dbo.DetalleVentas AS D
    INNER JOIN BikeZ.dbo.Ventas AS V
        ON D.VentaID = V.VentaID
    WHERE V.VendedorID IS NULL
),
Destino AS (
    SELECT
        COUNT_BIG(*) AS DetallesSinVendedorDestino
    FROM dbo.FactVentas
    WHERE VendedorKey = -1
)
SELECT
    O.DetallesSinVendedorOrigen,
    D.DetallesSinVendedorDestino,
    O.DetallesSinVendedorOrigen
        - D.DetallesSinVendedorDestino
        AS Diferencia
FROM Origen AS O
CROSS JOIN Destino AS D;
GO


-- =========================================
-- 6. VALIDACION DE INTEGRIDAD REFERENCIAL
-- =========================================

-- Verificar que las claves dimensionales
-- mantengan sus relaciones correspondientes.

SELECT
    COUNT(*) AS TotalRegistros,

    SUM(
        CASE
            WHEN T1.TiempoID IS NULL THEN 1
            ELSE 0
        END
    ) AS FechaVentaInvalida,

    SUM(
        CASE
            WHEN T2.TiempoID IS NULL
             AND F.FechaEnvioID IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS FechaEnvioInvalida,

    SUM(
        CASE
            WHEN C.ClienteKey IS NULL THEN 1
            ELSE 0
        END
    ) AS ClienteInvalido,

    SUM(
        CASE
            WHEN P.ProductoKey IS NULL THEN 1
            ELSE 0
        END
    ) AS ProductoInvalido,

    SUM(
        CASE
            WHEN E.VendedorKey IS NULL THEN 1
            ELSE 0
        END
    ) AS VendedorInvalido,

    SUM(
        CASE
            WHEN TR.TerritorioKey IS NULL THEN 1
            ELSE 0
        END
    ) AS TerritorioInvalido

FROM dbo.FactVentas AS F

LEFT JOIN dbo.DimTiempo AS T1
    ON F.FechaVentaID = T1.TiempoID

LEFT JOIN dbo.DimTiempo AS T2
    ON F.FechaEnvioID = T2.TiempoID

LEFT JOIN dbo.DimCliente AS C
    ON F.ClienteKey = C.ClienteKey

LEFT JOIN dbo.DimProducto AS P
    ON F.ProductoKey = P.ProductoKey

LEFT JOIN dbo.DimEmpleado AS E
    ON F.VendedorKey = E.VendedorKey

LEFT JOIN dbo.DimTerritorio AS TR
    ON F.TerritorioKey = TR.TerritorioKey;
GO


-- =========================================
-- 7. VALIDACION DE VALORES NULOS
-- =========================================

-- Revisar los campos relevantes de FactVentas.

SELECT
    COUNT(*) AS TotalRegistros,

    SUM(CASE WHEN FechaVentaID IS NULL
        THEN 1 ELSE 0 END) AS FechaVentaNula,

    SUM(CASE WHEN FechaEnvioID IS NULL
        THEN 1 ELSE 0 END) AS FechaEnvioNula,

    SUM(CASE WHEN ClienteKey IS NULL
        THEN 1 ELSE 0 END) AS ClienteNulo,

    SUM(CASE WHEN ProductoKey IS NULL
        THEN 1 ELSE 0 END) AS ProductoNulo,

    SUM(CASE WHEN VendedorKey IS NULL
        THEN 1 ELSE 0 END) AS VendedorNulo,

    SUM(CASE WHEN TerritorioKey IS NULL
        THEN 1 ELSE 0 END) AS TerritorioNulo,

    SUM(CASE WHEN MontoTotal IS NULL
        THEN 1 ELSE 0 END) AS ImporteNulo

FROM dbo.FactVentas;
GO


-- =========================================
-- 8. RESUMEN FINAL DE LA CARGA
-- =========================================

-- Indicadores finales para documentacion
-- y presentacion del proyecto.

SELECT
    COUNT(*) AS TotalDetalles,

    COUNT(DISTINCT VentaID)
        AS VentasDistintas,

    COUNT(DISTINCT DetalleVentaID)
        AS DetallesUnicos,

    SUM(Cantidad)
        AS UnidadesVendidas,

    SUM(MontoTotal)
        AS ImporteTotal,

    SUM(
        CASE
            WHEN VendedorKey = -1 THEN 1
            ELSE 0
        END
    ) AS DetallesSinVendedor

FROM dbo.FactVentas;
GO
