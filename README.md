# Certamen 2 (Fase 2) - Inteligencia de Negocios

## Caso Seleccionado
Caso N°2: "Bike Z" .
## Integrantes y Seccion
- Francisco Javier Angel (300)
- Constanza Venegas      (300)
- Victor Novoa           (300)
- Sebastian Miranda      (300)
## Descripcion del Problema
El propietario de Bike Z ha decidido implementar Inteligencia de Negocios a su negocio de ventas de motocross
## Objetivo del proyecto
Presentar una solucion que permita a los encargados tomar mejores desiciones respecto a su negocio de motocross
## KPI definidos
- Ingresos por territorio: Suma(cantidad*precio unitario)
- Top Productos: Suma(cantidad) agrupados por productos
- Ventas por vendedor:  Suma(Total Venta) 
## Modelo Dimensional
Para el Data Warehouse BikeZ_DW se eligió un modelo dimensional en estrella para facilitar las consultas analíticas y la generación de reportes de negocio. El diseño centraliza las métricas del proceso de ventas en una tabla de hechos (FactVentas), la cual se conecta directamente a sus dimensiones descriptivas (DimCliente, DimProducto, DimEmpleado, DimTerritorio y DimTiempo) mediante claves sustitutas, simplificando las uniones y optimizando el rendimiento de la información histórica.
## Proceso de negocio
La venta de articulos de motocross
## Granularidad
Cada fila representa un detalle de venta, no necesariamente una venta completa.
## Dimensiones
### DimTiempo: Contiene todo el contexto temporal para las fechas de venta y envío.
- Atributos: TiempoID (Llave Primaria), Fecha, Anio, Trimestre, Mes, NombreMes, Dia, DiaSemana.
### DimProducto: Consolida la información del artículo e integra la jerarquía de categorías.
- Atributos: ProductoKey (Llave Primaria), ProductoID, ProductoName, Color, Categoria.
### DimCliente: Almacena el catálogo de compradores de motocross.
- Atributos: ClienteKey (Llave Primaria), ClienteID, Nombre, Apellido.
### DimEmpleado: Registra al personal de ventas e incluye el registro especial -1 para consistencia.
- Atributos: VendedorKey (Llave Primaria), EmpleadoID, Cargo, Genero, EstadoCivil
### DimTerritorio: Denormaliza la estructura geográfica, unificando los datos de territorios, grupos y países en una sola dimensión perimetral.
- Atributos: TerritorioKey (Llave Primaria), TerritorioID, Territorio, Pais, Grupo.
## Tabla de hechos y medidas
- Tabla de Hechos: FactsVenta
- Cantidad: número de unidades vendidas.
- Precio Unitario: precio registrado para cada producto.
- Monto Total: importe generado por las ventas.
- Recuento Fact Ventas: cantidad de registros de detalle de ventas.
## Proceso ETL - Fase 1
Disponible en la carpeta "etl"
## Cubo OLAP - Fase 2
Disponible en la carpeta "OLAP"
## Tecnologias utilizadas
*   **Motor de Base de Datos:** SQL Server 2019 Developer Edition — Motor principal utilizado para alojar la base de datos transaccional original BikeZ y dar soporte físico a las tablas del Data Warehouse BikeZ_DW.
*   **Gestor de Base de Datos:** SQL Server Management Studio (SSMS) — Entorno gráfico integrado para la administración de la infraestructura de datos, diseño de diagramas, ejecución de scripts de creación (.sql) y desarrollo de las consultas de auditoría de calidad.
*   **Entorno de Desarrollo (IDE):** Visual Studio Community — Plataforma base utilizada para centralizar y administrar el proyecto institucional de Business Intelligence.
*   **Herramienta de Integración (ETL):** Microsoft Data Tools Integration Services (SSIS) — Extensión de desarrollo especializada utilizada para diseñar, construir y ejecutar el paquete de flujo de control y las transformaciones secuenciales ETL_FactVentas.dtsx.
*   **Control de Versiones:** GitHub / GitHub Desktop — Herramientas utilizadas para el control de versiones del código y componentes del paquete de integración, asegurando el registro de la colaboración individual de los integrantes del equipo.
*   **Entorno de Procesamiento Analítico (OLAP):** SQL Server Analysis Services (SSAS) — Herramienta utilizada para diseñar, implementar y procesar el cubo OLAP, permitiendo analizar la información del Data Warehouse mediante dimensiones, jerarquías y medidas.
*   **Herramienta de Visualización (BI):** Microsoft Power BI Desktop — Herramienta utilizada para desarrollar dashboards e informes interactivos, representando los indicadores clave de desempeño (KPI) y facilitando el análisis de los resultados del negocio.
## Distribucion de responsabilidades y aportes
- Francisco Javier Angel - Analisis de caso, determinar KPI pertinentes, Aplicar los 4 pasos de Kimball, Creacion del repositorio y aportar al README.md
- Constanza Venegas - Diseñar modelo dimensional, implementar modelo dimensional en SQL server
- Sebastian Miranda - Construir proceso ETL con SSIS
- Victor Novoa - Aplicar ttransformaciones y asegurar calidad de datos, Ejecutar y validar ETL
## Presentacion
https://canva.link/tvwj6xv59nrmm57
