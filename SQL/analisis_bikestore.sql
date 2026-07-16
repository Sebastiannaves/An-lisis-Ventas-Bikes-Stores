/*=============================================================

OBJETIVO:

BikeStores necesita identificar los factores que afectan el desempeño comercial de sus sucursales para optimizar las ventas, 
mejorar la gestión del inventario y apoyar la toma de decisiones estratégicas mediante indicadores de negocio.

Cada consulta responde una pregunta de negocio que posteriormente
será utilizada en el dashboard de Power BI.

=============================================================*/

	/* Panorama general:
	 1. ¿Cuáles son los ingresos, la cantidad de órdenes y el ticket promedio de cada sucursal? */
	SELECT
		T1.store_id,
		T1.store_name,
		SUM((T3.quantity * T3.list_price) * (1-T3.discount)) AS ingresos,
		COUNT(DISTINCT(T2.order_id)) AS cantidad_ordenes,
		SUM((T3.quantity * T3.list_price) * (1-T3.discount))/COUNT(DISTINCT(T2.order_id)) AS ticket_Prom
	FROM
		dbo.stores T1
		INNER JOIN dbo.orders T2
		ON T1.store_id = T2.store_id
		INNER JOIN dbo.order_items T3
		ON T3.order_id = T2.order_id
	GROUP BY
		T1.store_id,
		T1.store_name
	ORDER BY
		ingresos DESC

	/* Factor 1: Clientes
	 1.1. ¿Cuál es el ingreso promedio generado por cliente en cada sucursal? */
	SELECT
		IngresosPorCliente.store_id,
		T3.store_name,
		AVG(IngresosPorCliente.ingresos) as ingresos_prom_cliente
	FROM
		(
			SELECT
				T1.store_id,
				T1.customer_id,
				SUM((T2.quantity * T2.list_price) * (1-T2.discount)) AS ingresos
			FROM
				dbo.orders T1
				LEFT OUTER JOIN dbo.order_items T2
				ON T2.order_id = T1.order_id
			GROUP BY
				T1.store_id,
				T1.customer_id
		) AS IngresosPorCliente
		INNER JOIN dbo.stores T3 
		ON IngresosPorCliente.store_id = T3.store_id
	GROUP BY
		IngresosPorCliente.store_id,
		T3.store_name
	/* 1.2. ¿Cuántas órdenes realiza en promedio cada cliente? */
	SELECT
		ResumenSucursal.store_id,
		T3.store_name,
		ResumenSucursal.nro_ordenes,
		ResumenSucursal.nro_clientes,
		CAST(CAST(ResumenSucursal.nro_ordenes AS DECIMAL(10,2)) / ResumenSucursal.nro_clientes AS DECIMAL(10,2)) AS frecuencia_compra
	FROM
		(
			SELECT
				T1.store_id,
				COUNT(T1.order_id) AS nro_ordenes,
				COUNT(DISTINCT(T1.customer_id)) AS nro_clientes
			FROM
				dbo.orders T1
			GROUP BY
				T1.store_id
		) AS ResumenSucursal
		INNER JOIN dbo.stores T3 
		ON ResumenSucursal.store_id = T3.store_id

	/* 1.3. ¿Cuántos clientes realizaron una segunda compra o más en cada sucursal? */
	WITH ClientesRecurrentes AS
	(
		SELECT
			ComprasPorCliente.store_id,
			(SELECT COUNT(DISTINCT(B.customer_id)) 
			 FROM dbo.orders B
			 WHERE B.store_id = ComprasPorCliente.store_id) AS nro_clientes_total,
			 COUNT(DISTINCT(ComprasPorCliente.customer_id)) AS nroclientes_compra_segunda_vez
		FROM
		(
			SELECT
				T2.store_id,
				T1.customer_id,
				T2.order_id,
				ROW_NUMBER() OVER(PARTITION BY T2.store_id, T1.customer_id ORDER BY T2.order_id ASC) AS nro_compra
			FROM
				dbo.customers T1
				INNER JOIN dbo.orders T2
				ON T2.customer_id = T1.customer_id
		) AS ComprasPorCliente
		WHERE
			nro_compra >= 2
		GROUP BY
			ComprasPorCliente.store_id
	)
	SELECT
		CR.store_id,
		T3.store_name,
		CR.nro_clientes_total,
		CR.nroclientes_compra_segunda_vez,
		CONCAT(CAST(100 * CAST(CR.nroclientes_compra_segunda_vez AS decimal(10,2)) / CR.nro_clientes_total AS DECIMAL(10,2)), '%') AS porcentaje_recompra
	FROM
		ClientesRecurrentes CR
		INNER JOIN dbo.stores T3 
		ON CR.store_id = T3.store_id
	
	/* 1.4. ¿Qué tipo de clientes generan mayores ingresos en cada sucursal, clientes nuevos o recurrentes? */
	WITH IngresosTipoCliente AS
	(
	SELECT
		ClientesPorSucursal.store_id,
		SUM(CASE WHEN ClientesPorSucursal.nro_ordenes = 1 THEN ClientesPorSucursal.ingresos ELSE 0 END) AS clientes_nuevos,
		SUM(CASE WHEN ClientesPorSucursal.nro_ordenes >=2 THEN ClientesPorSucursal.ingresos ELSE 0 END) AS clientes_recurrentes
	FROM
	(
		SELECT
			T1.store_id,
			T1.customer_id,
			COUNT(DISTINCT(T1.order_id)) AS nro_ordenes,
			SUM((T2.quantity * T2.list_price) * (1-T2.discount)) AS ingresos
		FROM
			dbo.orders T1
			LEFT OUTER JOIN dbo.order_items T2
			ON T2.order_id = T1.order_id
		GROUP BY
			T1.store_id,
			T1.customer_id
	) AS ClientesPorSucursal
	GROUP BY
		ClientesPorSucursal.store_id
	)
	SELECT
		IT.store_id,
		T3.store_name,
		IT.clientes_nuevos,
		IT.clientes_recurrentes,
		CONCAT(CAST(100 * IT.clientes_recurrentes / (IT.clientes_nuevos + IT.clientes_recurrentes) AS DECIMAL(10,2)), '%') AS porcentaje_ingresos_recurrentes
	FROM
		IngresosTipoCliente IT
		INNER JOIN dbo.stores T3 
		ON IT.store_id = T3.store_id

	/* 1.5. ¿Los ingresos de cada sucursal provienen principalmente de un grupo reducido de ciudades? */
	SELECT
		T2.store_id,
		T4.store_name,
		T1.city,
		SUM((T3.quantity * T3.list_price) * (1-T3.discount)) AS ingresos,
		COUNT(T1.city) OVER(PARTITION BY T2.store_id) AS nro_ciudad_sucursal
	FROM
		dbo.customers T1
		LEFT OUTER JOIN dbo.orders T2
		ON T2.customer_id = T1.customer_id
		INNER JOIN dbo.order_items T3
		ON T3.order_id = T2.order_id
		INNER JOIN dbo.stores T4 
		ON T4.store_id = T2.store_id
	GROUP BY
		T2.store_id,
		T4.store_name,
		T1.city
	ORDER BY
		T2.store_id ASC,
		ingresos DESC

	/* Factor 2: Categorías 
	2.1. ¿Qué categorías representan la mayor participación de los ingresos en cada sucursal? */
	WITH IngresosPorCategoria AS
	(
	SELECT
		T3.store_id,
		T1.category_id,
		SUM((T2.quantity * T2.list_price) * (1-T2.discount)) AS ingresos
	FROM
		dbo.products T1
		INNER JOIN dbo.order_items T2
		ON T2.product_id = T1.product_id
		INNER JOIN dbo.orders T3
		ON T3.order_id = T2.order_id
	GROUP BY
		T3.store_id,
		T1.category_id
	), ParticipacionCategoria AS
	(
	SELECT
		IC.store_id,
		IC.category_id,
		IC.ingresos AS ingresos,
		SUM(IC.ingresos) OVER(PARTITION BY IC.store_id) AS ingresos_total
	FROM
		IngresosPorCategoria IC
	)
	SELECT
		PC.store_id,
		T3.store_name,
		C3.category_name,
		PC.ingresos,
		PC.ingresos_total,
		CONCAT(CAST(100 * PC.ingresos / PC.ingresos_total AS DECIMAL(10,2)), '%') AS porcentaje_participacion
	FROM
		ParticipacionCategoria PC
		INNER JOIN dbo.categories C3
		ON PC.category_id = C3.category_id
		INNER JOIN dbo.stores T3 
		ON PC.store_id = T3.store_id
	ORDER BY
		PC.store_id ASC,
		ingresos DESC

	/* FACTOR 3: MARCAS
	3.1. ¿Qué marcas representan la mayor participación en los ingresos de cada sucursal? */
	WITH IngresosPorMarca AS
	(
	SELECT
		T1.store_id,
		T3.brand_id,
		SUM((T2.quantity * T2.list_price) * (1-T2.discount)) AS ingresos
	FROM
		dbo.orders T1
		INNER JOIN dbo.order_items T2
		ON T2.order_id = T1.order_id
		INNER JOIN dbo.products T3
		ON T3.product_id = T2.product_id
	GROUP BY
		T1.store_id,
		T3.brand_id
	), ParticipacionMarca AS
	(
	SELECT
		IM.store_id,
		IM.brand_id,
		IM.ingresos,
		SUM(IM.ingresos) OVER(PARTITION BY IM.store_id) AS ingresos_total
	FROM
		IngresosPorMarca IM
	)
	SELECT
		PM.store_id,
		T4.store_name,
		C3.brand_name,
		PM.ingresos,
		PM.ingresos_total,
		CONCAT(CAST(100 * PM.ingresos / PM.ingresos_total AS DECIMAL(10,2)), '%') AS porcentaje_participacion
	FROM
		ParticipacionMarca PM
		INNER JOIN dbo.brands C3
		ON C3.brand_id = PM.brand_id
		INNER JOIN dbo.stores T4
		ON PM.store_id = T4.store_id
	ORDER BY
		PM.store_id ASC,
		PM.ingresos DESC

	/* FACTOR 4: Stock 
	4.1. ¿Las diferencias de desempeño entre sucursales pueden estar relacionadas con la disponibilidad de productos? */
	SELECT
		T1.store_id,
		T4.store_name,
		T3.category_name,                   -- Reemplazar por T2.brand_id para visualizar el stock de las marcas
		SUM(T1.quantity) AS stock_categoria,
		SUM(SUM(T1.quantity)) OVER(PARTITION BY T1.store_id) AS stock_total
	FROM
		dbo.stocks T1
		LEFT OUTER JOIN dbo.products T2
		ON T2.product_id = T1.product_id
		LEFT OUTER JOIN dbo.categories T3
		ON T3.category_id = T2.category_id
		INNER JOIN dbo.stores T4 
		ON T1.store_id = T4.store_id
	GROUP BY
		T1.store_id,
		T4.store_name,
		T3.category_name                     -- Reemplazar por T2.brand_id para visualizar el stock de las marcas
	ORDER BY 
		T1.store_id ASC,
		stock_categoria DESC

	/* FACTOR 5: Vendedores
	5.1. ¿Qué porcentaje de las ventas aporta cada vendedor dentro de su sucursal? */ 
	SELECT
		VentasPorVendedor.store_id,
		T4.store_name,
		VentasPorVendedor.vendedor,
		VentasPorVendedor.ingresos,
		VentasPorVendedor.ingreso_sucursal,
		CASE
			 WHEN VentasPorVendedor.ingresos IS NULL THEN '0%'
		ELSE CONCAT(CAST(100.0 * VentasPorVendedor.ingresos / VentasPorVendedor.ingreso_sucursal AS DECIMAL(10,2)), '%')
		END AS participacion
	FROM
	(
	SELECT
		T1.store_id,
		T1.first_name + ' ' + T1.last_name AS vendedor,
		SUM((T3.quantity * T3.list_price) * (1-T3.discount)) AS ingresos,
		SUM(SUM((T3.quantity * T3.list_price) * (1-T3.discount))) OVER(PARTITION BY T1.store_id) AS ingreso_sucursal
	FROM
		dbo.staffs T1
		LEFT OUTER JOIN dbo.orders T2
		ON T2.staff_id = T1.staff_id
		LEFT OUTER JOIN dbo.order_items T3
		ON T3.order_id = T2.order_id
	GROUP BY
		T1.store_id,
		T1.first_name + ' ' + T1.last_name
	) AS VentasPorVendedor
	INNER JOIN dbo.stores T4 
	ON VentasPorVendedor.store_id = T4.store_id
	ORDER BY
		VentasPorVendedor.store_id ASC,
		VentasPorVendedor.ingresos DESC
	


