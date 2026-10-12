# BikeZ — ETL de FactVentas

Certamen 2 — Inteligencia de Negocios  
Modelo dimensional y ETL

## 1. Descripción

El paquete `ETL_FactVentas.dtsx` fue desarrollado en Visual Studio 2026 utilizando SQL Server Integration Services (SSIS).

Su objetivo es extraer los registros de ventas desde la base transaccional `BikeZ`, transformar los identificadores originales en claves dimensionales y cargar los datos en `BikeZ_DW.dbo.FactVentas`.

## 2. Requisitos

Para ejecutar el paquete se necesita:

- SQL Server 2019 con la base `BikeZ` restaurada.
- Base dimensional `BikeZ_DW` creada.
- Cinco dimensiones previamente cargadas: `DimTiempo`, `DimCliente`, `DimProducto`, `DimEmpleado` y `DimTerritorio`.
- Visual Studio 2026 con la extensión SQL Server Integration Services Projects.
- Conectividad con la instancia local de SQL Server.

## 3. Conexiones utilizadas

| Conexión           | Base de datos | Función |

| localhost.BikeZ    | BikeZ         | Origen transaccional |
| localhost.BikeZ_DW | BikeZ_DW      | Búsqueda de dimensiones y carga de hechos |

Estas conexiones deben adaptarse al servidor SQL Server de cada integrante.

## 4. Estructura del flujo de datos

El paquete está formado por los siguientes componentes:

1. `Origen_Ventas_BikeZ`
2. `Lookup_FechaVenta`
3. `Lookup_FechaEnvio`
4. `Lookup_Cliente`
5. `Lookup_Producto`
6. `Lookup_Vendedor`
7. `Lookup_Territorio`
8. `Destino_FactVentas`

Los Lookups recuperan las claves de las dimensiones para relacionarlas con la tabla de hechos.

## 5. Transformaciones realizadas

**Fechas:** se convierten las fechas originales al tipo `DATE` para relacionarlas con `DimTiempo`.

**Vendedores sin asignar:** los valores nulos de `VendedorID` se reemplazan por `-1`, utilizando el registro especial de `DimEmpleado`.

**Importe de venta:** se calcula multiplicando `Cantidad` por `PrecioUnitario`, utilizando precisión `DECIMAL(19,4)`.

## 6. Procedimiento de ejecución

1. Abrir la solución del proyecto SSIS en Visual Studio.
2. Abrir `ETL_FactVentas.dtsx`.
3. Verificar las conexiones OLE DB a `BikeZ` y `BikeZ_DW`.
4. Comprobar que las dimensiones estén cargadas.
5. Verificar que `FactVentas` esté vacía antes de una carga inicial completa.
6. Ejecutar el paquete mediante **Ejecutar paquete**.
7. Revisar que todos los componentes terminen correctamente.
8. Ejecutar las consultas de validación del archivo `04_02_validar_factventas_PLANTILLA.sql`.

## 7. Resultados obtenidos

La primera ejecución del paquete se completó correctamente.

| Indicador                      | Resultado |

| Detalles cargados              | 121.317 |
| Detalles únicos                | 121.317 |
| Unidades vendidas              | 274.914 |
| Importe total                  | 110.373.889,3134 |
| Detalles sin vendedor asignado | 60.397 |
| Claves dimensionales inválidas | 0 |

Los registros cargados y el importe total coincidieron con los valores calculados previamente en la base transaccional.

## 8. Limitaciones

El proceso corresponde a una carga inicial completa. Pero no evita que se duplique los datos en caso de cargar nuevamente los datos.

Si el paquete se ejecuta nuevamente sobre una tabla `FactVentas` poblada, pueden generarse errores por claves primarias duplicadas.