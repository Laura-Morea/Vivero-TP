-- =====================================================
-- Consultas de prueba (testers) - MySQL 8.0.16+
-- Ejecutar sobre la base cargada con vivero_completo.sql.
-- Cada consulta indica qué valida o qué pregunta de negocio responde.
-- =====================================================

USE vivero;

-- -----------------------------------------------------
-- 1. Top 3 vendedores por facturación
-- -----------------------------------------------------
SELECT v.id_vendedor,
       CONCAT(v.apellido, ', ', v.nombre) AS vendedor,
       COUNT(t.id_venta)                  AS cantidad_tickets,
       SUM(t.total_facturado)             AS total_facturado
  FROM vendedor v
  JOIN ticket_venta t ON t.id_vendedor = v.id_vendedor
 GROUP BY v.id_vendedor, v.apellido, v.nombre
 ORDER BY total_facturado DESC
 LIMIT 3;

-- -----------------------------------------------------
-- 2. Top 3 productos más vendidos por unidades (sin servicios)
-- -----------------------------------------------------
SELECT p.id_producto,
       p.nombre,
       p.tipo,
       SUM(dv.cantidad) AS unidades_vendidas,
       SUM(dv.subtotal) AS facturado
  FROM producto p
  JOIN detalle_venta dv ON dv.id_producto = p.id_producto
 WHERE p.tipo <> 'servicio'
 GROUP BY p.id_producto, p.nombre, p.tipo
 ORDER BY unidades_vendidas DESC
 LIMIT 3;

-- -----------------------------------------------------
-- 3. Producto más facturado de cada tipo (planta, insumo, servicio)
--    Usa una función de ventana para rankear dentro de cada tipo.
-- -----------------------------------------------------
SELECT tipo, nombre, facturado
  FROM (SELECT p.tipo,
               p.nombre,
               SUM(dv.subtotal) AS facturado,
               RANK() OVER (PARTITION BY p.tipo ORDER BY SUM(dv.subtotal) DESC) AS puesto
          FROM producto p
          JOIN detalle_venta dv ON dv.id_producto = p.id_producto
         GROUP BY p.id_producto, p.tipo, p.nombre) ranking
 WHERE puesto = 1
 ORDER BY facturado DESC;

-- -----------------------------------------------------
-- 4. Ventas mensuales: cantidad de tickets, total y ticket promedio
-- -----------------------------------------------------
SELECT DATE_FORMAT(fecha, '%Y-%m')     AS mes,
       COUNT(*)                        AS cantidad_tickets,
       SUM(total_facturado)            AS total_facturado,
       ROUND(AVG(total_facturado), 2)  AS ticket_promedio
  FROM ticket_venta
 GROUP BY mes
 ORDER BY mes;

-- -----------------------------------------------------
-- 5. Facturación por forma de pago y su porcentaje sobre el total
-- -----------------------------------------------------
SELECT forma_de_pago,
       COUNT(*)             AS cantidad_tickets,
       SUM(total_facturado) AS total_facturado,
       ROUND(100 * SUM(total_facturado) / (SELECT SUM(total_facturado) FROM ticket_venta), 2) AS porcentaje
  FROM ticket_venta
 GROUP BY forma_de_pago
 ORDER BY total_facturado DESC;

-- -----------------------------------------------------
-- 6. Top 3 clientes por monto comprado, y cuánto se vendió a
--    consumidor final (tickets sin cliente identificado)
-- -----------------------------------------------------
(SELECT CONCAT(c.apellido, ', ', c.nombre) AS cliente,
        COUNT(t.id_venta)                  AS cantidad_tickets,
        SUM(t.total_facturado)             AS total_comprado
   FROM cliente c
   JOIN ticket_venta t ON t.id_cliente = c.id_cliente
  GROUP BY c.id_cliente, c.apellido, c.nombre
  ORDER BY total_comprado DESC
  LIMIT 3)
UNION ALL
(SELECT 'Consumidor final', COUNT(*), SUM(total_facturado)
   FROM ticket_venta
  WHERE id_cliente IS NULL);

-- -----------------------------------------------------
-- 7. Productos a reponer: stock menor a 10 unidades
-- -----------------------------------------------------
SELECT id_producto, nombre, tipo, cantidad_stock
  FROM producto
 WHERE tipo <> 'servicio'
   AND cantidad_stock < 10
 ORDER BY cantidad_stock, nombre;

-- -----------------------------------------------------
-- 8. Margen bruto por producto vendido
--    (precio de venta cobrado vs. precio de compra vigente)
-- -----------------------------------------------------
SELECT p.nombre,
       SUM(dv.cantidad)                                    AS unidades,
       SUM(dv.subtotal)                                    AS facturado,
       SUM(dv.cantidad * p.precio_compra)                  AS costo,
       SUM(dv.subtotal) - SUM(dv.cantidad * p.precio_compra) AS margen,
       ROUND(100 * (SUM(dv.subtotal) - SUM(dv.cantidad * p.precio_compra))
                 / SUM(dv.subtotal), 2)                    AS margen_pct
  FROM producto p
  JOIN detalle_venta dv ON dv.id_producto = p.id_producto
 WHERE p.tipo <> 'servicio'
 GROUP BY p.id_producto, p.nombre
 ORDER BY margen DESC;

-- -----------------------------------------------------
-- 9. Compras por proveedor
-- -----------------------------------------------------
SELECT pr.nombre_empresa,
       pr.cuit,
       COUNT(c.id_compra) AS cantidad_compras,
       SUM(c.total)       AS total_comprado,
       MAX(c.fecha)       AS ultima_compra
  FROM proveedor pr
  LEFT JOIN compra c ON c.id_proveedor = pr.id_proveedor
 GROUP BY pr.id_proveedor, pr.nombre_empresa, pr.cuit
 ORDER BY total_comprado DESC;

-- -----------------------------------------------------
-- 10. Plantas de interior para poca o media luz, con su tipo
--     (consulta sobre la especialización planta -> producto)
-- -----------------------------------------------------
SELECT p.nombre,
       pl.nombre_cientifico,
       tp.nombre AS tipo_planta,
       pl.nivel_luz,
       pl.riego_cada_dias,
       p.precio_venta,
       p.cantidad_stock
  FROM planta pl
  JOIN producto p     ON p.id_producto     = pl.id_producto
  JOIN tipo_planta tp ON tp.id_tipo_planta = pl.id_tipo_planta
 WHERE pl.de_interior = TRUE
   AND pl.nivel_luz IN ('baja', 'media')
 ORDER BY pl.nivel_luz, p.nombre;

-- -----------------------------------------------------
-- 11. Servicios vendidos, con su tipo y si son a domicilio
-- -----------------------------------------------------
SELECT p.nombre,
       ts.nombre                  AS tipo_servicio,
       s.a_domicilio,
       COUNT(dv.id_venta)         AS veces_vendido,
       COALESCE(SUM(dv.subtotal), 0) AS facturado
  FROM servicio s
  JOIN producto p       ON p.id_producto       = s.id_producto
  JOIN tipo_servicio ts ON ts.id_tipo_servicio = s.id_tipo_servicio
  LEFT JOIN detalle_venta dv ON dv.id_producto = p.id_producto
 GROUP BY p.id_producto, p.nombre, ts.nombre, s.a_domicilio
 ORDER BY facturado DESC;

-- -----------------------------------------------------
-- 12. Productos que nunca se vendieron
-- -----------------------------------------------------
SELECT p.id_producto, p.nombre, p.tipo, p.cantidad_stock
  FROM producto p
 WHERE NOT EXISTS (SELECT 1 FROM detalle_venta dv WHERE dv.id_producto = p.id_producto)
 ORDER BY p.tipo, p.nombre;

-- -----------------------------------------------------
-- 13. Detalle de un ticket (como se imprimiría)
-- -----------------------------------------------------
SELECT t.id_venta,
       t.fecha,
       COALESCE(CONCAT(c.apellido, ', ', c.nombre), 'Consumidor final') AS cliente,
       CONCAT(v.apellido, ', ', v.nombre) AS vendedor,
       p.nombre                           AS producto,
       dv.cantidad,
       dv.precio_unitario,
       dv.subtotal,
       t.total_facturado
  FROM ticket_venta t
  LEFT JOIN cliente c   ON c.id_cliente  = t.id_cliente
  JOIN vendedor v       ON v.id_vendedor = t.id_vendedor
  JOIN detalle_venta dv ON dv.id_venta   = t.id_venta
  JOIN producto p       ON p.id_producto = dv.id_producto
 WHERE t.id_venta = 3;

-- -----------------------------------------------------
-- 14. Control de consistencia de los triggers:
--     stock actual = unidades compradas - unidades vendidas
--     y total de cada ticket = suma de sus subtotales.
--     Ambas consultas deben devolver 0 filas.
-- -----------------------------------------------------
SELECT p.id_producto, p.nombre, p.cantidad_stock,
       COALESCE(dc.comprado, 0) - COALESCE(dv.vendido, 0) AS stock_esperado
  FROM producto p
  LEFT JOIN (SELECT id_producto, SUM(cantidad) AS comprado
               FROM detalle_compra GROUP BY id_producto) dc ON dc.id_producto = p.id_producto
  LEFT JOIN (SELECT id_producto, SUM(cantidad) AS vendido
               FROM detalle_venta GROUP BY id_producto) dv ON dv.id_producto = p.id_producto
 WHERE p.tipo <> 'servicio'
   AND p.cantidad_stock <> COALESCE(dc.comprado, 0) - COALESCE(dv.vendido, 0);

SELECT t.id_venta, t.total_facturado, SUM(dv.subtotal) AS suma_detalles
  FROM ticket_venta t
  JOIN detalle_venta dv ON dv.id_venta = t.id_venta
 GROUP BY t.id_venta, t.total_facturado
HAVING t.total_facturado <> SUM(dv.subtotal);

-- -----------------------------------------------------
-- 15. Prueba de trigger: una venta descuenta stock
--     Se hace dentro de una transacción y se deshace al final.
-- -----------------------------------------------------
START TRANSACTION;

SELECT nombre, cantidad_stock AS stock_antes FROM producto WHERE id_producto = 7;

INSERT INTO ticket_venta (id_cliente, id_vendedor, forma_de_pago) VALUES (NULL, 1, 'efectivo');
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
VALUES (LAST_INSERT_ID(), 7, 2, 16500.00);

SELECT nombre, cantidad_stock AS stock_despues FROM producto WHERE id_producto = 7;
SELECT id_venta, total_facturado FROM ticket_venta ORDER BY id_venta DESC LIMIT 1;

ROLLBACK;

-- =====================================================
-- PRUEBAS NEGATIVAS
-- Cada sentencia DEBE fallar: demuestra que una restricción o un
-- trigger impide cargar datos inválidos. Se indica el error esperado.
--
-- El cliente mysql corta en el primer error, así que esta sección se
-- ejecuta con:   mysql --force -u <usuario> -p < queries.sql
-- (en Workbench, ejecutar cada sentencia por separado).
-- Todo va dentro de una transacción que se deshace al final, así la
-- base queda igual aunque alguna prueba no fallara.
-- =====================================================

START TRANSACTION;

-- -----------------------------------------------------
-- N1. Vender más unidades que el stock disponible
--     Error esperado: 'Stock insuficiente para el producto' (trg_detalle_venta_bi)
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
VALUES (1, 5, 100, 22000.00);

-- -----------------------------------------------------
-- N2. Aumentar la cantidad de un detalle de venta por encima del stock
--     Error esperado: 'Stock insuficiente para el producto' (trg_detalle_venta_bu)
-- -----------------------------------------------------
UPDATE detalle_venta SET cantidad = 500 WHERE id_venta = 4 AND id_producto = 5;

-- -----------------------------------------------------
-- N3. Cambiar el producto de un detalle ya cargado
--     Error esperado: 'No se puede cambiar la venta ni el producto...' (trg_detalle_venta_bu)
-- -----------------------------------------------------
UPDATE detalle_venta SET id_producto = 2 WHERE id_venta = 1 AND id_producto = 1;

-- -----------------------------------------------------
-- N4. Registrar la compra de un servicio
--     Error esperado: 'No se pueden registrar compras de servicios' (trg_detalle_compra_bi)
-- -----------------------------------------------------
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario)
VALUES (1, 18, 1, 100.00);

-- -----------------------------------------------------
-- N5. Anular una compra cuyo stock ya se vendió
--     (del limonero se compraron 6 y se vendieron 2: quedaría en -2)
--     Error esperado: CHECK 'chk_producto_stock_no_negativo'
-- -----------------------------------------------------
DELETE FROM detalle_compra WHERE id_compra = 2 AND id_producto = 5;

-- -----------------------------------------------------
-- N6. Cargar como planta un producto que es insumo
--     Error esperado: FK 'fk_planta_producto' (la FK compuesta exige tipo = 'planta')
-- -----------------------------------------------------
INSERT INTO planta (id_producto, id_tipo_planta) VALUES (11, 1);

-- -----------------------------------------------------
-- N7. Planta sin precio de compra
--     Error esperado: CHECK 'chk_producto_stock_segun_tipo'
-- -----------------------------------------------------
INSERT INTO producto (nombre, tipo, cantidad_stock, precio_compra, precio_venta)
VALUES ('Helecho', 'planta', 0, NULL, 5000.00);

-- -----------------------------------------------------
-- N8. Servicio con stock
--     Error esperado: CHECK 'chk_producto_stock_segun_tipo'
-- -----------------------------------------------------
INSERT INTO producto (nombre, tipo, cantidad_stock, precio_compra, precio_venta)
VALUES ('Fumigación', 'servicio', 10, NULL, 20000.00);

-- -----------------------------------------------------
-- N9. Tipo de producto inexistente
--     Error esperado: CHECK 'chk_producto_tipo'
-- -----------------------------------------------------
INSERT INTO producto (nombre, tipo, cantidad_stock, precio_compra, precio_venta)
VALUES ('Semillas de tomate', 'semilla', 0, 300.00, 800.00);

-- -----------------------------------------------------
-- N10. Precio de venta negativo
--      Error esperado: CHECK 'chk_producto_precios'
-- -----------------------------------------------------
UPDATE producto SET precio_venta = -100 WHERE id_producto = 1;

-- -----------------------------------------------------
-- N11. Detalle de venta con cantidad 0
--      Error esperado: CHECK 'chk_dventa_cantidad'
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
VALUES (1, 2, 0, 4800.00);

-- -----------------------------------------------------
-- N12. Forma de pago fuera de las permitidas
--      Error esperado: 'Data truncated for column forma_de_pago' (ENUM, modo estricto)
-- -----------------------------------------------------
INSERT INTO ticket_venta (id_cliente, id_vendedor, forma_de_pago)
VALUES (1, 1, 'cheque');

-- -----------------------------------------------------
-- N13. Cliente con DNI repetido
--      Error esperado: 'Duplicate entry' en la clave única de dni
-- -----------------------------------------------------
INSERT INTO cliente (nombre, apellido, dni) VALUES ('Laura', 'Benítez', '32456789');

-- -----------------------------------------------------
-- N14. Ticket de un vendedor que no existe
--      Error esperado: FK 'fk_ticket_vendedor'
-- -----------------------------------------------------
INSERT INTO ticket_venta (id_cliente, id_vendedor, forma_de_pago)
VALUES (1, 99, 'efectivo');

-- -----------------------------------------------------
-- N15. Borrar un cliente que tiene ventas
--      Error esperado: FK 'fk_ticket_cliente' (ON DELETE RESTRICT)
-- -----------------------------------------------------
DELETE FROM cliente WHERE id_cliente = 1;

-- -----------------------------------------------------
-- N16. Borrar un ticket sin borrar antes sus detalles
--      Error esperado: FK 'fk_dventa_venta' (ON DELETE RESTRICT)
-- -----------------------------------------------------
DELETE FROM ticket_venta WHERE id_venta = 1;

ROLLBACK;
