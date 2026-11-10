# ETL de Dimensiones — Proyecto BikeZ

## Descripción

Este proyecto implementa un proceso ETL con **SQL Server Integration Services (SSIS)** para cargar las dimensiones de un Data Warehouse del proyecto BikeZ. Los datos operacionales se extraen desde la base `BikeZ` y se transforman/cargan en `BikeZ_DW`.

El modelo dimensional acordado utiliza un **esquema en estrella**: cinco dimensiones describen el contexto de las ventas y una tabla de hechos central (`FactVentas`) almacena los detalles y las métricas. Este repositorio se centra en la carga de las dimensiones; el paquete de `FactVentas` se mantiene separado para evitar que dos paquetes carguen las mismas filas.

## Tecnologías

- SQL Server y SQL Server Management Studio (SSMS).
- Visual Studio con SQL Server Integration Services (SSIS).
- Administradores de conexión OLE DB.
- Consultas SQL para extraer, transformar y validar datos.

## Bases de datos

- **Origen:** `BikeZ` — base operacional con las tablas de ventas, detalles, productos, clientes, empleados y territorios.
- **Destino:** `BikeZ_DW` — Data Warehouse con las dimensiones y la tabla de hechos.

Las conexiones del proyecto están configuradas para `localhost` y autenticación integrada de Windows. Si el servidor local tiene otro nombre, hay que editar los administradores de conexión OLE DB en Visual Studio. Antes de ejecutar, confirmar que las conexiones de origen apunten a `BikeZ` y las de destino a `BikeZ_DW`.

## Dimensiones incluidas

| Dimensión | Origen y transformaciones | Resultado validado |
|---|---|---:|
| `DimProducto` | Lee `dbo.Productos`; utiliza conversión de datos y búsqueda de categoría. Mantiene una ruta para coincidencias y otra para productos sin categoría encontrada. | 504 productos distintos; se conservan los 209 productos sin categoría. |
| `DimCliente` | Lee `dbo.Clientes` y carga los atributos de identificación y nombre del cliente. Se deben convertir los textos a los tipos que requiera el destino. | 19.820 clientes distintos. |
| `DimEmpleado` | Lee `dbo.Empleados` y carga los atributos del empleado. | 290 empleados de origen. |
| `DimTerritorio` | Lee `dbo.Territorios`; utiliza `dbo.Paises` y una búsqueda por `PaisID` para incluir el nombre del país. | 10 territorios. |
| `DimTiempo` | Extrae fechas distintas de `Ventas.Fecha` y `Ventas.FechaEnvio`; obtiene año, trimestre, mes, nombre del mes, día y día de la semana. | 1.133 fechas distintas, sin fechas nulas en la validación realizada. |

### Registro especial de empleado

Después de cargar los 290 empleados de origen, la tarea `SQL_Crear_Vendedor_Sin_Asignar` inserta el registro especial `VendedorKey = -1`, `EmpleadoID = -1`. Este registro permite representar los detalles de venta que no tienen un vendedor asignado y mantiene la integridad referencial del modelo.

Por eso, el recuento validado de `DimEmpleado` es **291 filas**: 290 empleados más el registro especial.

## Flujo de control de SSIS

El paquete dimensional contiene las siguientes tareas:

- `DFT_Cargar_Dimensiones`: carga de productos.
- `DFT_Cargar_Clientes`: carga de clientes.
- `DFT_Cargar_Empleados`: carga de empleados.
- `SQL_Crear_Vendedor_Sin_Asignar`: crea el registro especial `-1`.
- `DFT_Cargar_Territorios`: carga territorios y nombres de países.
- `DFT_Cargar_Tiempo`: carga las fechas de venta y envío.
- `SQL_Limpiar_DW`: tarea de limpieza del Data Warehouse.
- `DFT_Cargar_FactVentas`: carga de hechos que pertenece al flujo anterior del proyecto.

Para la integración acordada, `SQL_Limpiar_DW` y `DFT_Cargar_FactVentas` están **deshabilitadas** en el paquete dimensional. La carga de hechos debe ejecutarse con el paquete separado preparado por el integrante responsable de `FactVentas`, una vez que las dimensiones estén cargadas y las estructuras estén alineadas.

> **Advertencia:** las cargas dimensionales añaden registros. No se debe ejecutar de nuevo una carga sobre una dimensión ya poblada sin preparar una recarga coordinada, porque se pueden generar duplicados. La limpieza del Data Warehouse debe coordinarse entre los integrantes y nunca ejecutarse por separado sobre datos que se quieren conservar.

## Validaciones realizadas

En `BikeZ_DW` se comprobaron los siguientes resultados después de corregir registros duplicados:

| Tabla | Filas | Claves distintas / validación |
|---|---:|---:|
| `DimProducto` | 504 | 504 `ProductoID` distintos |
| `DimCliente` | 19.820 | 19.820 `ClienteID` distintos |
| `DimEmpleado` | 291 | Incluye `VendedorKey = -1` |
| `DimTerritorio` | 10 | 10 `TerritorioID` distintos |
| `DimTiempo` | 1.133 | 1.133 fechas distintas; cero fechas nulas |
| `FactVentas` | 0 al preparar la integración | La carga final corresponde al paquete separado de hechos |

En una ejecución individual anterior del flujo de hechos se validaron 121.317 detalles sin duplicados y un importe total de `110373889.3134`, coincidente con el total calculado en `BikeZ.dbo.DetalleVentas`. Ese resultado corresponde a la prueba previa del flujo; la integración final debe volver a comprobarse con el paquete de hechos acordado.

## Alineación del esquema e integración

El esquema dimensional acordado indica, entre otros puntos:

- `DimProducto.ProductoName` debe ser `VARCHAR(150)`.
- `DimTiempo.Fecha` debe utilizar `DATE` para que las búsquedas de fechas sean compatibles con el paquete de hechos.
- Las columnas de texto de `DimCliente`, `DimEmpleado` y `DimTerritorio` deben coincidir en tipo y longitud con las columnas de destino.
- `DimEmpleado` debe conservar el registro especial `-1`.
- La tabla `FactVentas` y sus nombres/tipos de columnas deben ajustarse a la versión final del esquema y al paquete de hechos compartido; no se debe habilitar la carga anterior `DFT_Cargar_FactVentas` en este paquete.

La integración se considera completa después de actualizar los metadatos de SSIS, resolver los errores de validación, confirmar que todas las búsquedas de fechas y dimensiones devuelven las claves correctas y ejecutar los paquetes en el orden acordado: **dimensiones primero, hechos después**.

## Ejecución recomendada

1. Verificar que las conexiones OLE DB apunten al servidor correcto y a las bases `BikeZ` y `BikeZ_DW`.
2. Confirmar que el esquema de destino coincide con el modelo dimensional aprobado.
3. Preparar una carga nueva de manera coordinada si las dimensiones ya tienen datos.
4. Ejecutar el paquete dimensional con las tareas de limpieza y hechos deshabilitadas.
5. Validar los recuentos de las cinco dimensiones y la presencia del empleado `-1`.
6. Ejecutar el paquete de hechos compartido por el integrante responsable.
7. Validar que `FactVentas` tenga 121.317 detalles, que no existan combinaciones duplicadas de `VentaID` y `DetalleVentaID`, que las claves dimensionales sean válidas y que los importes coincidan con el origen.

## Estado del proyecto

Las cinco cargas dimensionales se ejecutaron y sus recuentos quedaron validados en SSMS. La adaptación final de los tipos de columnas y la compatibilidad entre los Lookups del paquete de hechos y el esquema acordado siguen siendo parte de la integración. Por lo tanto, el proyecto no debe marcarse como integración finalizada hasta completar esas comprobaciones.
