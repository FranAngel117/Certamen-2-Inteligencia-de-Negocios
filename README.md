# Certamen 2 - Inteligencia de Negocios

## Caso Seleccionado
Caso N°2: "Bike Z"
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
- Ticket Promedio: Suma(total venta) / conteo(ventas)
- Top Productos: Suma(cantidad) agrupados por productos
- Tiempo de envio: Promedio(fecha envío-fecha)
- Ventas por vendedor:  Suma(Total Venta) 
## Modelo Dimensional
Modelo dimensional tipo estrella
## Proceso de negocio
La venta de articulos de motocross
## Granularidad
Una fila dentro del dataset representa un registro de una venta que es el nivel mas bajo posible, cosa que nos permite por venta individual y no por venta total
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
- Tabla de Hechos: Hechos_Venta
- Metricas: Cantidad(unidades_vendidas), PrecioUnitario(se usa para calculos), Total_Venta(cantidad*PrecioUnitario), Costo_envio(si se aplica)
## Proceso ETL - Fase 1
## Cubo OLAP - Fase 2
## Tecnologias utilizadas
## Estructura del repositorio
## Instrucciones de ejecución/revisión
## Distribucion de responsabilidades y aportes
- Francisco Javier Angel - Analisis de caso, determinar KPI pertinentes, Aplicar los 4 pasos de Kimball, Creacion del repositorio y aportar al README.md
- Constanza Venegas - Diseñar modelo dimensional, implementar modelo dimensional en SQL server
- Sebastian Miranda - Construir proceso ETL con SSIS
- Victor Novoa - Aplicar ttransformaciones y asegurar calidad de datos, Ejecutar y validar ETL