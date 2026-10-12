# Integrante 4 — Diseño del ETL de FactVentas

## 1. Objetivo

Diseñar e implementar el proceso ETL que permita extraer los registros de ventas desde la base transaccional `BikeZ`, transformarlos y cargarlos en la tabla de hechos `BikeZ_DW.dbo.FactVentas`, utilizando SQL Server Integration Services (SSIS).

## 2. Herramientas utilizadas

- SQL Server 2019.
- SQL Server Management Studio (SSMS).
- Visual Studio 2026 con SQL Server Integration Services.
- GitHub Desktop para el control de versiones.

## 3. Extracción de datos

Se configuró un componente `Origen_Ventas_BikeZ` mediante OLE DB Source, utilizando una consulta SQL que relaciona las tablas `Ventas` y `DetalleVentas` a través del identificador `VentaID`.

La consulta extrae los identificadores de venta, detalle, cliente, producto, vendedor y territorio, además de las fechas, cantidades y precios unitarios.

Se definió una granularidad de una fila por detalle de venta.

## 4. Transformación de datos

Se realizaron las siguientes transformaciones:

**Conversión de fechas:** Se utilizó `CAST(... AS DATE)` para transformar las fechas originales al formato requerido por `DimTiempo`.

**Cálculo del importe:** Se calculó `ImporteDetalle` mediante la multiplicación de `Cantidad × PrecioUnitario`, conservando cuatro decimales.

**Tratamiento de vendedores nulos:** Los valores nulos de `VendedorID` se reemplazaron por `-1` mediante una expresión `CASE`, permitiendo relacionarlos con el registro especial de `DimEmpleado`.

## 5. Transformaciones Lookup

Se implementaron seis Lookups para recuperar las claves correspondientes a las dimensiones.

| Lookup            | Relación de búsqueda                      | Clave recuperada |

| Lookup_FechaVenta | FechaVenta → DimTiempo.Fecha              | FechaVentaID |
| Lookup_FechaEnvio | FechaEnvio → DimTiempo.Fecha              | FechaEnvioID |
| Lookup_Cliente    | ClienteID → DimCliente.ClienteID          | ClienteKey |
| Lookup_Producto   | ProductoID → DimProducto.ProductoID       | ProductoKey |
| Lookup_Vendedor   | VendedorID_ETL → DimEmpleado.EmpleadoID   | VendedorKey |
| Lookup_Territorio | TerritorioID → DimTerritorio.TerritorioID | TerritorioKey |

Las transformaciones permitieron relacionar los identificadores originales con las claves sustitutas del modelo dimensional.

## 6. Carga de datos

Se configuró un componente OLE DB Destination denominado `Destino_FactVentas`, conectado a `BikeZ_DW.dbo.FactVentas`.

El destino utiliza carga rápida, con un tamaño máximo de confirmación de 10.000 filas.

Se asignaron los identificadores, claves dimensionales y medidas. La columna calculada `ImporteDetalle` fue relacionada con `MontoTotal`.

## 7. Resultados de ejecución

El paquete `ETL_FactVentas.dtsx` se ejecutó correctamente en Visual Studio 2026.

| Indicador                      | Resultado |

| Registros cargados             | 121.317 |
| Detalles únicos                | 121.317 |
| Unidades vendidas              | 274.914 |
| Importe total                  | 110.373.889,3134 |
| Detalles sin vendedor asignado | 60.397 |

El importe total del destino coincidió con el valor calculado previamente sobre los datos originales.

## 8. Validaciones finales

Se comprobó la integridad referencial de los registros cargados, obteniendo cero claves dimensionales inválidas.

También se verificó que los registros de detalle mantienen identificadores únicos.

## 9. Limitaciones

El paquete implementa una carga inicial completa y no incorpora todavía un mecanismo de carga incremental o prevención de registros duplicados en ejecuciones posteriores.

Por lo tanto, antes de repetir la ejecución sobre una tabla de hechos poblada, es necesario definir una estrategia de recarga.

## 10. Conclusión

El ETL implementado permitió integrar correctamente los datos de ventas al Data Warehouse, conservando la cantidad de registros, las relaciones dimensionales y los importes calculados.

El proceso constituye la base para el análisis de indicadores comerciales del proyecto BikeZ.