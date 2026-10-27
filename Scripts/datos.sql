-- =====================================================
-- Datos de prueba (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de schema.sql, integridad_referencial.sql,
-- indices.sql y triggers.sql.
--
-- Los productos se dan de alta con stock 0: el stock, el precio_compra
-- vigente y los totales los completan los triggers al cargar las compras
-- y las ventas. Por eso las compras se cargan antes que las ventas.
-- =====================================================

USE vivero;

-- -----------------------------------------------------
-- Personas y proveedores
-- -----------------------------------------------------

INSERT INTO vendedor (id_vendedor, nombre, apellido, dni, telefono, mail, direccion) VALUES
    (1, 'Ana',     'Gutiérrez', '29111222', '1140001111', 'ana.gutierrez@viverotp.com.ar',  'Av. Rivadavia 4520, CABA'),
    (2, 'Pablo',   'Herrera',   '33444555', '1140002222', 'pablo.herrera@viverotp.com.ar',  'Lavalle 1800, CABA'),
    (3, 'Carla',   'Molina',    '36777888', '1140003333', 'carla.molina@viverotp.com.ar',   'Av. Cabildo 2100, CABA'),
    (4, 'Nicolás', 'Acosta',    '31222333', '1140004444', 'nicolas.acosta@viverotp.com.ar', 'Av. San Martín 3300, CABA');

-- El cliente 1 es el "consumidor final": ventas a quien no se identifica
INSERT INTO cliente (id_cliente, nombre, apellido, dni, telefono) VALUES
    (1,  'Consumidor final', NULL,  NULL,       NULL),
    (2,  'Lucía',     'Fernández', '32456789',  '1145238890'),
    (3,  'Martín',    'Gómez',     '28987654',  '1156781234'),
    (4,  'Sofía',     'Rodríguez', '40123456',  NULL),
    (5,  'Javier',    'López',     '25678901',  '1160112233'),
    (6,  'Valentina', 'Martínez',  NULL,        '1133445566'),
    (7,  'Diego',     'Pérez',     '35111222',  '1122998877'),
    (8,  'Camila',    'Sánchez',   'AAB123456', '+5491144556677'),  -- pasaporte
    (9,  'Tomás',     'Romero',    NULL,        NULL),
    (10, 'Florencia', 'Díaz',      '42345678',  '1177889900'),
    (11, 'Agustín',   'Torres',    '30999888',  '1111223344');

INSERT INTO proveedor (id_proveedor, nombre_empresa, cuit, telefono) VALUES
    (1, 'Viveros del Delta S.A.', '30712345678', '1147281000'),
    (2, 'Agroinsumos Pampa SRL',  '30709876543', '1146592000'),
    (3, 'Cerámicas Litoral',      '33715556669', '3424553000'),
    (4, 'Semillería Norte SRL',   '30718889991', '1147904000');

-- -----------------------------------------------------
-- Productos: plantas (1-10 y 18), insumos (11-17, 19 y 20).
-- 18 y 19 ingresaron hace poco y todavía no se vendieron.
-- 20 está dado de baja (activo = FALSE): tiene stock pero no se vende más.
-- precio_compra es un valor de referencia: lo pisa la primera compra.
-- -----------------------------------------------------

INSERT INTO producto (id_producto, cantidad_stock, stock_minimo, precio_compra, precio_venta, activo) VALUES
    (1,  0,  5, 1500.00,  3500.00, TRUE),
    (2,  0,  5, 2000.00,  4800.00, TRUE),
    (3,  0,  5, 1800.00,  4200.00, TRUE),
    (4,  0,  5, 1200.00,  3000.00, TRUE),
    (5,  0,  5, 9000.00, 22000.00, TRUE),
    (6,  0,  5, 2500.00,  6000.00, TRUE),
    (7,  0,  4, 7000.00, 16500.00, TRUE),
    (8,  0,  5, 3000.00,  7200.00, TRUE),
    (9,  0,  6, 4000.00,  9500.00, TRUE),
    (10, 0, 50,  400.00,  1000.00, TRUE),
    (11, 0, 10, 6000.00, 11000.00, TRUE),
    (12, 0,  8, 3500.00,  7000.00, TRUE),
    (13, 0, 20,  600.00,  1500.00, TRUE),
    (14, 0, 10, 4500.00,  9800.00, TRUE),
    (15, 0,  3, 8000.00, 16000.00, TRUE),
    (16, 0,  5, 3000.00,  6500.00, TRUE),
    (17, 0,  5, 1800.00,  3800.00, TRUE),
    (18, 0,  2, 8500.00, 19500.00, TRUE),
    (19, 0,  5, 1200.00,  2800.00, TRUE),
    (20, 0,  0,  500.00,  1200.00, FALSE);

INSERT INTO planta (id_planta, nombre, tipo_planta, de_interior, descripcion, nivel_de_luz, riego_cada_dias, id_producto) VALUES
    (1,  'Echeveria',          'suculenta',        FALSE, 'Echeveria elegans. Maceta n°10',            'alto',   10, 1),
    (2,  'Aloe vera',          'suculenta',        TRUE,  'Aloe barbadensis. Maceta n°12',             'medio',  14, 2),
    (3,  'Lavanda',            'aromática',        FALSE, 'Lavandula angustifolia. Maceta n°14',       'alto',    4, 3),
    (4,  'Romero',             'aromática',        FALSE, 'Salvia rosmarinus. Maceta n°14',            'alto',    5, 4),
    (5,  'Limonero injertado', 'frutal',           FALSE, 'Citrus limon. Ejemplar de 1,2 m en bolsa',  'alto',    3, 5),
    (6,  'Potus',              'ornamental',       TRUE,  'Epipremnum aureum. Maceta colgante n°16',   'bajo',    7, 6),
    (7,  'Monstera deliciosa', 'ornamental',       TRUE,  'Monstera deliciosa. Maceta n°20',           'medio',   7, 7),
    (8,  'Sansevieria',        'ornamental',       TRUE,  'Dracaena trifasciata. Maceta n°16',         'bajo',   15, 8),
    (9,  'Jazmín del Cabo',    'arbusto',          FALSE, 'Gardenia jasminoides. Maceta n°18',         'medio',   3, 9),
    (10, 'Petunia',            'flor de estación', FALSE, 'Petunia x hybrida. Plantín en alvéolo',     'alto',    2, 10),
    (11, 'Ficus lyrata',       'ornamental',       TRUE,  'Ficus lyrata. Maceta n°24',                 'alto',    7, 18);

INSERT INTO insumo (id_insumo, nombre, descripcion, id_producto) VALUES
    (1, 'Sustrato universal 50 L',  'Bolsa de sustrato para macetas',      11),
    (2, 'Fertilizante líquido 1 L', 'Fertilizante NPK de uso general',     12),
    (3, 'Maceta plástica n°14',     'Maceta negra de plástico',            13),
    (4, 'Maceta cerámica n°20',     'Maceta esmaltada con plato',          14),
    (5, 'Tijera de podar',          'Tijera de una mano, hoja de acero',   15),
    (6, 'Insecticida 500 ml',       'Insecticida en aerosol para plantas', 16),
    (7, 'Perlita 5 L',              'Aditivo para drenaje de sustratos',   17),
    (8, 'Guantes de jardinería',    'Par de guantes de nitrilo, talle M',  19),
    (9, 'Maceta de barro n°12',     'Discontinuada por el proveedor',      20);

-- -----------------------------------------------------
-- Compras (subtotal, total_facturado, stock y precio_compra los
-- actualizan los triggers)
-- -----------------------------------------------------

INSERT INTO compra (id_compra, fecha, forma_de_pago, id_proveedor) VALUES
    (1, '2026-08-03', 'transferencia', 1),
    (2, '2026-08-17', 'transferencia', 1),
    (3, '2026-08-20', 'crédito',       2),
    (4, '2026-09-01', 'transferencia', 3),
    (5, '2026-09-10', 'efectivo',      4),
    (6, '2026-09-28', 'transferencia', 1),
    (7, '2026-10-05', 'débito',        2),
    (8, '2026-10-12', 'efectivo',      4);

INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (1, 1,  30, 1500.00), (1, 2, 20, 2000.00), (1, 6, 15, 2500.00), (1, 7, 8, 7000.00), (1, 8, 12, 3000.00),
    (2, 3,  25, 1800.00), (2, 4, 25, 1200.00), (2, 5,  6, 9000.00), (2, 9, 10, 4000.00),
    (3, 11, 20, 6000.00), (3, 12, 15, 3500.00), (3, 15, 5, 8000.00), (3, 16, 10, 3000.00), (3, 17, 15, 1800.00),
    (4, 13, 50,  600.00), (4, 14, 12, 4500.00), (4, 20, 10, 500.00),
    (5, 10, 120, 400.00),
    -- reposición con aumento de precio: actualiza precio_compra
    (6, 1,  20, 1650.00), (6, 6, 10, 2700.00), (6, 7, 5, 7400.00),
    -- productos nuevos (18 y 19) que todavía no tienen ventas
    (6, 18,  6, 8500.00),
    (7, 11, 15, 6400.00), (7, 12, 10, 3700.00), (7, 19, 20, 1200.00),
    (8, 10, 80,  420.00);

-- -----------------------------------------------------
-- Ventas (subtotal, total_facturado y stock los actualizan los triggers)
-- id_cliente = 1: consumidor final
-- -----------------------------------------------------

INSERT INTO venta (id_venta, fecha, forma_de_pago, id_cliente, id_vendedor) VALUES
    (1,  '2026-08-05', 'efectivo',      2,  1),
    (2,  '2026-08-06', 'efectivo',      1,  2),
    (3,  '2026-08-12', 'débito',        3,  1),
    (4,  '2026-08-21', 'crédito',       4,  3),
    (5,  '2026-08-25', 'transferencia', 5,  2),
    (6,  '2026-09-02', 'efectivo',      1,  4),
    (7,  '2026-09-05', 'débito',        6,  1),
    (8,  '2026-09-12', 'crédito',       7,  3),
    (9,  '2026-09-18', 'débito',        2,  2),
    (10, '2026-09-21', 'efectivo',      1,  4),
    (11, '2026-09-30', 'transferencia', 8,  1),
    (12, '2026-10-03', 'transferencia', 9,  3),
    (13, '2026-10-08', 'débito',        3,  2),
    (14, '2026-10-14', 'efectivo',      1,  1),
    (15, '2026-10-18', 'crédito',       10, 4),
    (16, '2026-10-20', 'transferencia', 11, 3);

INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario) VALUES
    (1,  1,  3,  3500.00), (1, 13, 3, 1500.00),
    (2,  10, 12, 1000.00),
    (3,  7,  1, 16500.00), (3, 14, 1, 9800.00), (3, 11, 1, 11000.00),
    (4,  5,  2, 22000.00), (4, 12, 1, 7000.00),
    (5,  9,  3,  9500.00), (5, 11, 2, 11000.00),
    (6,  3,  2,  4200.00), (6, 4, 2, 3000.00),
    (7,  6,  2,  6000.00), (7, 8, 1, 7200.00), (7, 13, 3, 1500.00),
    (8,  5,  1, 22000.00), (8, 15, 1, 16000.00),
    (9,  2,  2,  4800.00), (9, 17, 1, 3800.00),
    (10, 10, 24, 1000.00),
    (11, 16, 2,  6500.00), (11, 12, 2, 7000.00),
    (12, 7,  2, 16500.00), (12, 11, 2, 11000.00),
    (13, 9,  2,  9500.00), (13, 17, 2, 3800.00),
    (14, 1,  5,  3500.00), (14, 13, 5, 1500.00),
    (15, 8,  2,  7200.00), (15, 14, 2, 9800.00), (15, 6, 1, 6000.00),
    (16, 8,  1,  7200.00), (16, 12, 1, 7000.00);
