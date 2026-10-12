# Integrante 4 — Bitácora de validaciones de BikeZ

## 1. Objetivo

Analizar y validar los datos provenientes de la base transaccional BikeZ para preparar el proceso de extracción, transformación y carga (ETL) hacia la tabla de hechos `FactVentas` del Data Warehouse `BikeZ_DW`.

## 2. Análisis de los datos originales

Se analizaron las tablas `Ventas` y `DetalleVentas`, identificando su estructura, campos relevantes y relación mediante `VentaID`.

**Resultados:**

| Indicador                             | Resultado |

| Ventas registradas                    | 31.465 |
| Detalles de venta                     | 121.317 |
| Detalles sin venta asociada           | 0 |
| Identificadores de detalle duplicados | 0 |
| Ventas sin vendedor asignado          | 27.658 |

Se identificó que una venta puede contener varios detalles, por lo que se estableció una granularidad de una fila por detalle de venta para la tabla de hechos.

## 3. Validación de calidad de los datos

Se revisaron posibles valores nulos, cantidades inválidas y precios no positivos.

**Resultados:** No se encontraron cantidades nulas, precios nulos, cantidades iguales o menores que cero ni precios iguales o menores que cero.

Las ventas sin vendedor asignado se trataron mediante una clave especial `-1`, asociada al registro «Sin vendedor asignado» en `DimEmpleado`.

## 4. Validación de importes

Se calculó el importe individual mediante `Cantidad × PrecioUnitario`, utilizando precisión `DECIMAL(19,4)`.

| Indicador                  | Resultado |

| Importe total              | 110.373.889,3134 |
| Importe mínimo por detalle | 1,3740 |
| Importe máximo por detalle | 30.992,9100 |

Estos valores se utilizaron posteriormente como referencia para comprobar los resultados del ETL.

## 5. Ejecución del ETL en SSIS

Se creó el paquete `ETL_FactVentas.dtsx` en Visual Studio 2026, utilizando SQL Server Integration Services.

El flujo contempla un origen OLE DB, seis transformaciones Lookup y un destino OLE DB conectado a `BikeZ_DW.dbo.FactVentas`.

El proceso se ejecutó correctamente y los 121.317 detalles llegaron al destino.

## 6. Validación de FactVentas

Después de ejecutar el paquete ETL, se comprobaron los datos insertados.

| Indicador                      | Resultado |

| Registros cargados             | 121.317 |
| Detalles únicos                | 121.317 |
| Unidades vendidas              | 274.914 |
| Importe total                  | 110.373.889,3134 |
| Detalles sin vendedor asignado | 60.397 |

El número de detalles sin vendedor es superior al número de ventas sin vendedor, debido a que una misma venta puede contener varios productos.

## 7. Integridad referencial

Se realizaron consultas con `LEFT JOIN` para comprobar las relaciones entre `FactVentas` y sus cinco dimensiones.

No se encontraron registros con claves inválidas en las relaciones de fecha de venta, fecha de envío, cliente, producto, vendedor o territorio.

## 8. Conclusión

El proceso ETL permitió trasladar los 121.317 detalles desde la base transaccional al modelo dimensional, conservando la cantidad de registros y el importe total calculado previamente. Además, se validó la integridad referencial de los datos cargados.

La implementación corresponde a una carga inicial completa. La prevención de duplicaciones en ejecuciones posteriores queda identificada como una posible mejora futura.