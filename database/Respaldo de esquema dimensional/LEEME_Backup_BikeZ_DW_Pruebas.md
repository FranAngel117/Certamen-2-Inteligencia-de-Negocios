# Respaldo y validación final — BikeZ_DW_Pruebas

## 1. Descripción

Este documento acompaña el respaldo completo `BikeZ_DW_Pruebas.bak` del Data Warehouse del proyecto **BikeZ — Certamen 2 de Inteligencia de Negocios (Fase 1)**.

La base de pruebas se construyó utilizando el modelo dimensional del equipo y se pobló mediante dos paquetes SSIS ejecutados en este orden:

1. `ETL_Dimensiones_BikeZ.dtsx`: carga `DimCliente`, `DimProducto`, `DimEmpleado`, `DimTerritorio` y `DimTiempo`, incluido el vendedor especial sin asignar.
2. `ETL_FactVentas.dtsx`: carga los detalles de venta y recupera las claves de las dimensiones mediante seis Lookups.

**Importante:** el respaldo contiene datos ya cargados. No se deben volver a ejecutar los ETL sobre la base restaurada sin preparar previamente una estrategia de recarga, pues podrían aparecer errores por duplicados.

## 2. Resultados de la prueba integrada

Valores observados en SSMS después de ejecutar ambos ETL sobre `BikeZ_DW_Pruebas`:

| Tabla | Registros |
|---|---:|
| DimCliente | 19.820 |
| DimProducto | 504 |
| DimEmpleado | 291 |
| DimTerritorio | 10 |
| DimTiempo | 1.133 |
| FactVentas | 121.317 |

| Indicador | Resultado |
|---|---:|
| Detalles de venta únicos | 121.317 |
| Unidades vendidas | 274.914 |
| Importe total | 110373889.3134 |
| Detalles sin vendedor asignado | 60.397 |
| Diferencia de registros respecto al origen | 0 |
| Diferencia de unidades respecto al origen | 0 |
| Diferencia de importes respecto al origen | 0.0000 |
| Relaciones dimensionales inválidas | 0 |
| Claves naturales duplicadas en dimensiones | 0 |
| Claves compuestas duplicadas en FactVentas | 0 |

El registro especial tiene `EmpleadoID = -1` y `VendedorKey = -1`.

## 3. Consulta SQL de validación final

Ejecutar en **SQL Server Management Studio (SSMS)** después de restaurar el respaldo. Las consultas son solo de lectura y no modifican datos.

> **Requisito para la comparación con el origen:** también debe estar disponible la base transaccional `BikeZ` en la misma instancia. Si solo se restaura el DW, pueden ejecutarse los bloques 1, 2 y 4 a 7; el bloque 3 requiere la base `BikeZ`.

```sql
USE [BikeZ_DW_Pruebas];
GO

-- 1. Conteo de dimensiones y tabla de hechos
SELECT 'DimCliente' AS Tabla, COUNT(*) AS Registros FROM dbo.DimCliente
UNION ALL SELECT 'DimProducto', COUNT(*) FROM dbo.DimProducto
UNION ALL SELECT 'DimEmpleado', COUNT(*) FROM dbo.DimEmpleado
UNION ALL SELECT 'DimTerritorio', COUNT(*) FROM dbo.DimTerritorio
UNION ALL SELECT 'DimTiempo', COUNT(*) FROM dbo.DimTiempo
UNION ALL SELECT 'FactVentas', COUNT(*) FROM dbo.FactVentas;
GO

-- 2. Medidas finales de FactVentas
SELECT
    COUNT(*) AS TotalRegistros,
    COUNT(DISTINCT DetalleVentaID) AS DetallesUnicos,
    SUM(Cantidad) AS UnidadesVendidas,
    SUM(MontoTotal) AS ImporteTotal,
    SUM(CASE WHEN VendedorKey = -1 THEN 1 ELSE 0 END) AS DetallesSinVendedor
FROM dbo.FactVentas;
GO

-- 3. Comparación contra BikeZ (requiere base transaccional restaurada)
WITH Origen AS (
    SELECT
        COUNT_BIG(*) AS Registros,
        SUM(CAST(Cantidad AS BIGINT)) AS Unidades,
        SUM(CAST(Cantidad * PrecioUnitario AS DECIMAL(19,4))) AS Importe
    FROM BikeZ.dbo.DetalleVentas
),
Destino AS (
    SELECT
        COUNT_BIG(*) AS Registros,
        SUM(CAST(Cantidad AS BIGINT)) AS Unidades,
        SUM(MontoTotal) AS Importe
    FROM dbo.FactVentas
)
SELECT
    O.Registros AS RegistrosOrigen,
    D.Registros AS RegistrosDestino,
    O.Registros - D.Registros AS DiferenciaRegistros,
    O.Unidades AS UnidadesOrigen,
    D.Unidades AS UnidadesDestino,
    O.Unidades - D.Unidades AS DiferenciaUnidades,
    O.Importe AS ImporteOrigen,
    D.Importe AS ImporteDestino,
    O.Importe - D.Importe AS DiferenciaImporte
FROM Origen AS O
CROSS JOIN Destino AS D;
GO

-- 4. Integridad referencial de FactVentas
SELECT
    COUNT(*) AS TotalRegistros,
    SUM(CASE WHEN TV.TiempoID IS NULL THEN 1 ELSE 0 END) AS FechaVentaInvalida,
    SUM(CASE WHEN TE.TiempoID IS NULL AND F.FechaEnvioID IS NOT NULL THEN 1 ELSE 0 END) AS FechaEnvioInvalida,
    SUM(CASE WHEN C.ClienteKey IS NULL THEN 1 ELSE 0 END) AS ClienteInvalido,
    SUM(CASE WHEN P.ProductoKey IS NULL THEN 1 ELSE 0 END) AS ProductoInvalido,
    SUM(CASE WHEN E.VendedorKey IS NULL THEN 1 ELSE 0 END) AS VendedorInvalido,
    SUM(CASE WHEN T.TerritorioKey IS NULL THEN 1 ELSE 0 END) AS TerritorioInvalido
FROM dbo.FactVentas AS F
LEFT JOIN dbo.DimTiempo AS TV ON F.FechaVentaID = TV.TiempoID
LEFT JOIN dbo.DimTiempo AS TE ON F.FechaEnvioID = TE.TiempoID
LEFT JOIN dbo.DimCliente AS C ON F.ClienteKey = C.ClienteKey
LEFT JOIN dbo.DimProducto AS P ON F.ProductoKey = P.ProductoKey
LEFT JOIN dbo.DimEmpleado AS E ON F.VendedorKey = E.VendedorKey
LEFT JOIN dbo.DimTerritorio AS T ON F.TerritorioKey = T.TerritorioKey;
GO

-- 5. Registro especial de vendedor no asignado
SELECT VendedorKey, EmpleadoID, Cargo
FROM dbo.DimEmpleado
WHERE EmpleadoID = -1;
GO

-- 6. Duplicados de claves naturales en dimensiones
SELECT 'DimCliente' AS Tabla, COUNT(*) - COUNT(DISTINCT ClienteID) AS Duplicados FROM dbo.DimCliente
UNION ALL SELECT 'DimProducto', COUNT(*) - COUNT(DISTINCT ProductoID) FROM dbo.DimProducto
UNION ALL SELECT 'DimEmpleado', COUNT(*) - COUNT(DISTINCT EmpleadoID) FROM dbo.DimEmpleado
UNION ALL SELECT 'DimTerritorio', COUNT(*) - COUNT(DISTINCT TerritorioID) FROM dbo.DimTerritorio
UNION ALL SELECT 'DimTiempo', COUNT(*) - COUNT(DISTINCT Fecha) FROM dbo.DimTiempo;
GO

-- 7. Duplicados de clave compuesta en FactVentas: debe devolver cero filas
SELECT VentaID, DetalleVentaID, COUNT(*) AS Repeticiones
FROM dbo.FactVentas
GROUP BY VentaID, DetalleVentaID
HAVING COUNT(*) > 1;
GO
```

## 4. Restauración del respaldo

En SSMS: **Bases de datos → Restaurar base de datos → Dispositivo → seleccionar el archivo `.bak`**. Elegir un nombre de base adecuado y revisar las opciones de rutas físicas antes de confirmar. Si se restaura con un nombre distinto a `BikeZ_DW_Pruebas`, actualizar el comando `USE` del script de validación.

## 5. Consideraciones para GitHub

- El respaldo `.bak` es un entregable exigido para la Fase 1.
- Verificar el tamaño del archivo y las reglas de `.gitignore` del repositorio antes de subirlo.
- GitHub no acepta archivos de más de 100 MB mediante Git convencional; si corresponde, coordinar Git LFS o un mecanismo de entrega autorizado.
- No subir contraseñas, archivos personales de Visual Studio ni respaldos no necesarios.

## 6. Estado de la validación

**Resultado de la prueba local:** los dos paquetes SSIS se ejecutaron, las cinco dimensiones se cargaron y `FactVentas` quedó poblada con 121.317 registros. Los conteos, unidades e importes coincidieron con el origen; se observaron cero claves dimensionales inválidas y cero duplicados según las verificaciones indicadas.

Este documento registra los resultados observados en la base de pruebas; al restaurar el archivo `.bak` en otro equipo, se recomienda volver a ejecutar las consultas para comprobar el estado de esa restauración.
