-- =====================================================
-- Datos de prueba (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de schema.sql, integridad_referencial.sql,
-- indices.sql y triggers.sql.
--
-- Los ids los asigna AUTO_INCREMENT (solo se fija el cliente 1,
-- "Consumidor final"). Como schema.sql crea la base desde cero, cada
-- tabla numera sus filas 1, 2, 3... en el orden en que se insertan; las
-- FK de más abajo usan esos números, indicados en los comentarios.
--
-- Las fechas de compras y ventas son relativas al día en que se carga
-- (CURRENT_DATE - INTERVAL n DAY): los datos cubren siempre los últimos
-- tres meses, así las consultas por período (mes anterior, últimos 3
-- meses, etc.) devuelven resultados sin importar cuándo se ejecuten.
--
-- Los productos se dan de alta con stock 0 y precios en 0: el stock,
-- el precio_compra y el precio_venta vigentes y los totales los
-- completan los triggers al cargar las compras y las ventas. Por eso
-- las compras y las ventas se cargan intercaladas en orden cronológico.
-- =====================================================

USE vivero;

-- -----------------------------------------------------
-- Personas y proveedores
-- -----------------------------------------------------

-- vendedores 1 a 4
INSERT INTO vendedor (nombre, apellido, dni, telefono, mail, direccion) VALUES
    ('Ana',     'Gutiérrez', '29111222', '1140001111', 'ana.gutierrez@viverotp.com.ar',  'Av. Rivadavia 4520, CABA'),
    ('Pablo',   'Herrera',   '33444555', '1140002222', 'pablo.herrera@viverotp.com.ar',  'Lavalle 1800, CABA'),
    ('Carla',   'Molina',    '36777888', '1140003333', 'carla.molina@viverotp.com.ar',   'Av. Cabildo 2100, CABA'),
    ('Nicolás', 'Acosta',    '31222333', '1140004444', 'nicolas.acosta@viverotp.com.ar', 'Av. San Martín 3300, CABA');

-- El cliente 1 es el "consumidor final": ventas a quien no se identifica.
-- Es el único id fijo; el resto de los clientes toman 2 a 11.
INSERT INTO cliente (id_cliente, nombre, apellido, dni, telefono) VALUES
    (1, 'Consumidor final', NULL, NULL, NULL);

INSERT INTO cliente (nombre, apellido, dni, telefono) VALUES
    ('Lucía',     'Fernández', '32456789',  '1145238890'),       -- 2
    ('Martín',    'Gómez',     '28987654',  '1156781234'),       -- 3
    ('Sofía',     'Rodríguez', '40123456',  NULL),               -- 4
    ('Javier',    'López',     '25678901',  '1160112233'),       -- 5
    ('Valentina', 'Martínez',  NULL,        '1133445566'),       -- 6
    ('Diego',     'Pérez',     '35111222',  '1122998877'),       -- 7
    ('Camila',    'Sánchez',   'AAB123456', '+5491144556677'),   -- 8 (pasaporte)
    ('Tomás',     'Romero',    NULL,        NULL),               -- 9
    ('Florencia', 'Díaz',      '42345678',  '1177889900'),       -- 10
    ('Agustín',   'Torres',    '30999888',  '1111223344');       -- 11

-- proveedores 1 a 4
INSERT INTO proveedor (nombre_empresa, cuit, telefono) VALUES
    ('Viveros del Delta S.A.', '30712345678', '1147281000'),
    ('Agroinsumos Pampa SRL',  '30709876543', '1146592000'),
    ('Cerámicas Litoral',      '33715556669', '3424553000'),
    ('Semillería Norte SRL',   '30718889991', '1147904000');

-- -----------------------------------------------------
-- Productos: plantas (1-10 y 18), insumos (11-17, 19 y 20).
-- 18 y 19 ingresaron hace poco y todavía no se vendieron.
-- 20 está dado de baja (activo = FALSE): tiene stock pero no se vende más.
-- -----------------------------------------------------

INSERT INTO producto (cantidad_stock, stock_minimo, activo) VALUES
    (0,  5, TRUE),    -- 1  Echeveria
    (0,  5, TRUE),    -- 2  Aloe vera
    (0,  5, TRUE),    -- 3  Lavanda
    (0,  5, TRUE),    -- 4  Romero
    (0,  5, TRUE),    -- 5  Limonero injertado
    (0,  5, TRUE),    -- 6  Potus
    (0,  4, TRUE),    -- 7  Monstera deliciosa
    (0,  5, TRUE),    -- 8  Sansevieria
    (0,  6, TRUE),    -- 9  Jazmín del Cabo
    (0, 50, TRUE),    -- 10 Petunia
    (0, 10, TRUE),    -- 11 Sustrato universal 50 L
    (0,  8, TRUE),    -- 12 Fertilizante líquido 1 L
    (0, 20, TRUE),    -- 13 Maceta plástica n°14
    (0, 10, TRUE),    -- 14 Maceta cerámica n°20
    (0,  3, TRUE),    -- 15 Tijera de podar
    (0,  5, TRUE),    -- 16 Insecticida 500 ml
    (0,  5, TRUE),    -- 17 Perlita 5 L
    (0,  2, TRUE),    -- 18 Ficus lyrata
    (0,  5, TRUE),    -- 19 Guantes de jardinería
    (0,  0, FALSE);   -- 20 Maceta de barro n°12

-- plantas 1 a 11 (la última columna es el id_producto de arriba)
INSERT INTO planta (nombre, tipo_planta, de_interior, descripcion, nivel_de_luz, riego_cada_dias, id_producto) VALUES
    ('Echeveria',          'suculenta',        FALSE, 'Echeveria elegans. Maceta n°10',            'alto',   10, 1),
    ('Aloe vera',          'suculenta',        TRUE,  'Aloe barbadensis. Maceta n°12',             'medio',  14, 2),
    ('Lavanda',            'aromática',        FALSE, 'Lavandula angustifolia. Maceta n°14',       'alto',    4, 3),
    ('Romero',             'aromática',        FALSE, 'Salvia rosmarinus. Maceta n°14',            'alto',    5, 4),
    ('Limonero injertado', 'frutal',           FALSE, 'Citrus limon. Ejemplar de 1,2 m en bolsa',  'alto',    3, 5),
    ('Potus',              'ornamental',       TRUE,  'Epipremnum aureum. Maceta colgante n°16',   'bajo',    7, 6),
    ('Monstera deliciosa', 'ornamental',       TRUE,  'Monstera deliciosa. Maceta n°20',           'medio',   7, 7),
    ('Sansevieria',        'ornamental',       TRUE,  'Dracaena trifasciata. Maceta n°16',         'bajo',   15, 8),
    ('Jazmín del Cabo',    'arbusto',          FALSE, 'Gardenia jasminoides. Maceta n°18',         'medio',   3, 9),
    ('Petunia',            'flor de estación', FALSE, 'Petunia x hybrida. Plantín en alvéolo',     'alto',    2, 10),
    ('Ficus lyrata',       'ornamental',       TRUE,  'Ficus lyrata. Maceta n°24',                 'alto',    7, 18);

-- insumos 1 a 9 (la última columna es el id_producto de arriba)
INSERT INTO insumo (nombre, descripcion, id_producto) VALUES
    ('Sustrato universal 50 L',  'Bolsa de sustrato para macetas',      11),
    ('Fertilizante líquido 1 L', 'Fertilizante NPK de uso general',     12),
    ('Maceta plástica n°14',     'Maceta negra de plástico',            13),
    ('Maceta cerámica n°20',     'Maceta esmaltada con plato',          14),
    ('Tijera de podar',          'Tijera de una mano, hoja de acero',   15),
    ('Insecticida 500 ml',       'Insecticida en aerosol para plantas', 16),
    ('Perlita 5 L',              'Aditivo para drenaje de sustratos',   17),
    ('Guantes de jardinería',    'Par de guantes de nitrilo, talle M',  19),
    ('Maceta de barro n°12',     'Discontinuada por el proveedor',      20);

-- -----------------------------------------------------
-- Compras y ventas, en orden cronológico
-- Se cargan en el orden en que ocurrieron porque los triggers usan el
-- estado del producto en ese momento: cada compra suma stock y fija
-- precio_compra y precio_venta (+40%), y cada venta cobra el
-- precio_venta vigente y descuenta stock. Subtotales y totales también
-- los calculan los triggers.
--   detalle_compra: (id_compra, id_producto, cantidad, precio_unitario)
--   detalle_venta:  (id_venta, id_producto, cantidad)
--   venta: id_cliente = 1 es el consumidor final
-- Compras numeradas 1 a 8 y ventas 1 a 16, cada una en orden de fecha.
-- -----------------------------------------------------

-- compra 1 (Viveros del Delta)
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 95 DAY, 'transferencia', 1);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (1, 1, 30, 1500.00), (1, 2, 20, 2000.00), (1, 6, 15, 2500.00), (1, 7, 8, 7000.00), (1, 8, 12, 3000.00);

-- compra 2 (Viveros del Delta)
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 81 DAY, 'transferencia', 1);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (2, 3, 25, 1800.00), (2, 4, 25, 1200.00), (2, 5, 6, 9000.00), (2, 9, 10, 4000.00);

-- compra 3 (Agroinsumos Pampa)
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 78 DAY, 'crédito', 2);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (3, 11, 20, 6000.00), (3, 12, 15, 3500.00), (3, 15, 5, 8000.00), (3, 16, 10, 3000.00), (3, 17, 15, 1800.00);

-- venta 1
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 77 DAY, 'crédito', 4, 3);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (1, 5, 2), (1, 12, 1);

-- venta 2
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 73 DAY, 'transferencia', 5, 2);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (2, 9, 3), (2, 11, 2);

-- compra 4 (Cerámicas Litoral)
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 66 DAY, 'transferencia', 3);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (4, 13, 50, 600.00), (4, 14, 12, 4500.00), (4, 20, 10, 500.00);

-- venta 3 (consumidor final)
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 65 DAY, 'efectivo', 1, 4);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (3, 3, 2), (3, 4, 2);

-- venta 4
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 64 DAY, 'efectivo', 2, 1);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (4, 1, 3), (4, 13, 3);

-- venta 5
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 62 DAY, 'débito', 6, 1);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (5, 6, 2), (5, 8, 1), (5, 13, 3);

-- venta 6
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 59 DAY, 'débito', 3, 1);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (6, 7, 1), (6, 14, 1), (6, 11, 1);

-- compra 5 (Semillería Norte)
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 57 DAY, 'efectivo', 4);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (5, 10, 120, 400.00);

-- venta 7
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 55 DAY, 'crédito', 7, 3);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (7, 5, 1), (7, 15, 1);

-- venta 8 (consumidor final)
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 52 DAY, 'efectivo', 1, 2);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (8, 10, 12);

-- venta 9
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 49 DAY, 'débito', 2, 2);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (9, 2, 2), (9, 17, 1);

-- venta 10 (consumidor final)
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 46 DAY, 'efectivo', 1, 4);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (10, 10, 24);

-- compra 6 (Viveros del Delta)
-- reposición con aumento de precio (1, 6 y 7): sube su precio_venta;
-- el 18 es nuevo y todavía no tiene ventas
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 39 DAY, 'transferencia', 1);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (6, 1, 20, 1650.00), (6, 6, 10, 2700.00), (6, 7, 5, 7400.00), (6, 18, 6, 8500.00);

-- venta 11
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 37 DAY, 'transferencia', 8, 1);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (11, 16, 2), (11, 12, 2);

-- venta 12
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 34 DAY, 'transferencia', 9, 3);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (12, 7, 2), (12, 11, 2);

-- compra 7 (Agroinsumos Pampa)
-- aumento de precio del 11 y el 12; el 19 es nuevo y no tiene ventas
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 32 DAY, 'débito', 2);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (7, 11, 15, 6400.00), (7, 12, 10, 3700.00), (7, 19, 20, 1200.00);

-- venta 13
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 29 DAY, 'débito', 3, 2);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (13, 9, 2), (13, 17, 2);

-- compra 8 (Semillería Norte)
-- reposición de petunias con aumento de precio
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUES (CURRENT_DATE - INTERVAL 25 DAY, 'efectivo', 4);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (8, 10, 80, 420.00);

-- venta 14 (consumidor final)
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 23 DAY, 'efectivo', 1, 1);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (14, 1, 5), (14, 13, 5);

-- venta 15
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 19 DAY, 'crédito', 10, 4);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (15, 8, 2), (15, 14, 2), (15, 6, 1);

-- venta 16
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUES (CURRENT_DATE - INTERVAL 17 DAY, 'transferencia', 11, 3);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES
    (16, 8, 1), (16, 12, 1);
