## Analisis-Ventas-Bikes-Stores
Proyecto de análisis de ventas desarrollado con SQL Server y Power BI para evaluar el desempeño de cada sucursal e identificar los factores que influyen en sus ventas. Incluye modelado de datos, medidas DAX, KPIs y dashboards interactivos para apoyar la toma de decisiones.

## 1. Objetivo
Identificar los factores que afectan el desempeño comercial de las sucursales de BikeStores mediante el análisis de ventas, clientes, categorías, marcas, inventario y vendedores, utilizando SQL Server y Power BI.

## 2. Herramientas utilizadas
- SQL Server
- SQL Server Management Studio (SSMS)
- Power BI
- Power Query
- DAX

## 3. Preguntas de negocio
- ¿Cuáles son los ingresos, la cantidad de órdenes y el ticket promedio por sucursal?
- ¿Cuál es el ingreso promedio generado por cliente?
- ¿Cuál es la frecuencia promedio de compra?
- ¿Qué porcentaje de clientes realiza una segunda compra?
- ¿Los ingresos provienen principalmente de clientes nuevos o recurrentes?
- ¿Las categorías explican las diferencias entre sucursales?
- ¿Las marcas explican las diferencias entre sucursales?
- ¿El stock influye en el desempeño comercial?
- ¿Cómo se distribuyen las ventas entre los vendedores?
- ¿Los ingresos provienen de un grupo reducido de ciudades?

## 4 Metodología
1. Exploración de datos.
2. Realizar consultas SQL para responder las preguntas de negocio.
3. Conexión de SQL Server con Power BI, creación de tablas en Power Query y modelado de datos (esquema estrella).
4. Creación de medidas DAX.
5. Diseño de dashboards interactivos.
6. Obtención de conclusiones.

## 5. Consultas SQL
Las consultas SQL fueron desarrolladas para responder cada una de las preguntas de negocio planteadas durante el análisis.
📄 **Archivo completo:** [analisis_bikestore.sql](SQL/analisis_bikestore.sql)

Las consultas incluyen:
- Panorama general de ventas.
- Análisis de clientes.
- Análisis de categorías.
- Análisis de marcas.
- Análisis de inventario.
- Análisis de vendedores.
- Análisis por ciudades.

## 6. Power BI Dashboard
Presentación del archivo Power BI.

### 6.1 Modelado de datos
Se modificó el modelo de SQL a un modelo estrella para facilitar el análisis en Power BI. El modelo está compuesto por una tabla de hechos (Ventas) y las dimensiones de Productos, Clientes, Tiendas, Vendedores, Marcas, Categorías y Calendario.
![Modelo_datos](Imagenes/Modelo_datos.png)

### 6.2. Panorama General
Presentar una visión resumida del desempeño comercial de las sucursales.
![Dashboard General](Imagenes/pag1_resumen.png)

### 6.3. Customer Analysis
Analizar el comportamiento de los clientes mediante indicadores de valor, frecuencia de compra y recompra.
![Customer Analysis](Imagenes/pag2_clientes.png)



