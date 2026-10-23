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
-- Catálogos
-- -----------------------------------------------------

INSERT INTO tipo_planta (id_tipo_planta, nombre, descripcion) VALUES
    (1, 'Suculenta',       'Plantas de hojas carnosas que almacenan agua'),
    (2, 'Aromática',       'Plantas de uso culinario o medicinal'),
    (3, 'Frutal',          'Árboles y arbustos que dan fruto'),
    (4, 'Interior',        'Ornamentales adaptadas a poca luz'),
    (5, 'Arbusto',         'Arbustos ornamentales de exterior'),
    (6, 'Flor de estación', 'Plantines florales de temporada');

INSERT INTO tipo_servicio (id_tipo_servicio, nombre, descripcion) VALUES
    (1, 'Poda',             'Poda de árboles y arbustos'),
    (2, 'Diseño de jardín', 'Proyecto de paisajismo y selección de especies'),
    (3, 'Mantenimiento',    'Mantenimiento periódico de jardines y macetas'),
    (4, 'Trasplante',       'Cambio de maceta o traslado a tierra');

-- -----------------------------------------------------
-- Personas y proveedores
-- -----------------------------------------------------

INSERT INTO cliente (id_cliente, nombre, apellido, telefono, dni) VALUES
    (1,  'Lucía',     'Fernández', '11-4523-8890', '32456789'),
    (2,  'Martín',    'Gómez',     '11-5678-1234', '28987654'),
    (3,  'Sofía',     'Rodríguez', NULL,           '40123456'),
    (4,  'Javier',    'López',     '11-6011-2233', '25678901'),
    (5,  'Valentina', 'Martínez',  '11-3344-5566', NULL),
    (6,  'Diego',     'Pérez',     '11-2299-8877', '35111222'),
    (7,  'Camila',    'Sánchez',   '11-4455-6677', '38765432'),
    (8,  'Tomás',     'Romero',    NULL,           NULL),
    (9,  'Florencia', 'Díaz',      '11-7788-9900', '42345678'),
    (10, 'Agustín',   'Torres',    '11-1122-3344', '30999888');

INSERT INTO vendedor (id_vendedor, nombre, apellido, telefono, direccion, mail, dni) VALUES
    (1, 'Ana',     'Gutiérrez', '11-4000-1111', 'Av. Rivadavia 4520, CABA',  'ana.gutierrez@viverotp.com.ar',  '29111222'),
    (2, 'Pablo',   'Herrera',   '11-4000-2222', 'Lavalle 1800, CABA',        'pablo.herrera@viverotp.com.ar',  '33444555'),
    (3, 'Carla',   'Molina',    '11-4000-3333', 'Av. Cabildo 2100, CABA',    'carla.molina@viverotp.com.ar',   '36777888'),
    (4, 'Nicolás', 'Acosta',    '11-4000-4444', 'Av. San Martín 3300, CABA', 'nicolas.acosta@viverotp.com.ar', '31222333');

INSERT INTO proveedor (id_proveedor, nombre_empresa, telefono, cuit) VALUES
    (1, 'Viveros del Delta S.A.', '11-4728-1000', '30-71234567-8'),
    (2, 'Agroinsumos Pampa SRL',  '11-4659-2000', '30-70987654-3'),
    (3, 'Cerámicas Litoral',      '342-455-3000', '33-71555666-9'),
    (4, 'Semillería Norte SRL',   '11-4790-4000', '30-71888999-1');

-- -----------------------------------------------------
-- Productos: plantas (1-10), insumos (11-17), servicios (18-21) y
-- una planta y un insumo recién ingresados que todavía no se vendieron (22-23)
-- precio_compra es un valor de referencia: lo pisa la primera compra.
-- -----------------------------------------------------

INSERT INTO producto (id_producto, nombre, descripcion, tipo, cantidad_stock, precio_compra, precio_venta) VALUES
    (1,  'Echeveria',               'Maceta n°10',                        'planta',   0, 1500.00,   3500.00),
    (2,  'Aloe vera',               'Maceta n°12',                        'planta',   0, 2000.00,   4800.00),
    (3,  'Lavanda',                 'Maceta n°14',                        'planta',   0, 1800.00,   4200.00),
    (4,  'Romero',                  'Maceta n°14',                        'planta',   0, 1200.00,   3000.00),
    (5,  'Limonero injertado',      'Ejemplar de 1,2 m en bolsa',         'planta',   0, 9000.00,  22000.00),
    (6,  'Potus',                   'Maceta colgante n°16',               'planta',   0, 2500.00,   6000.00),
    (7,  'Monstera deliciosa',      'Maceta n°20',                        'planta',   0, 7000.00,  16500.00),
    (8,  'Sansevieria',             'Maceta n°16',                        'planta',   0, 3000.00,   7200.00),
    (9,  'Jazmín del Cabo',         'Maceta n°18',                        'planta',   0, 4000.00,   9500.00),
    (10, 'Petunia',                 'Plantín en alvéolo',                 'planta',   0,  400.00,   1000.00),
    (11, 'Sustrato universal 50 L', 'Bolsa de sustrato para macetas',     'insumo',   0, 6000.00,  11000.00),
    (12, 'Fertilizante líquido 1 L', 'Fertilizante NPK de uso general',   'insumo',   0, 3500.00,   7000.00),
    (13, 'Maceta plástica n°14',    'Maceta negra de plástico',           'insumo',   0,  600.00,   1500.00),
    (14, 'Maceta cerámica n°20',    'Maceta esmaltada con plato',         'insumo',   0, 4500.00,   9800.00),
    (15, 'Tijera de podar',         'Tijera de una mano, hoja de acero',  'insumo',   0, 8000.00,  16000.00),
    (16, 'Insecticida 500 ml',      'Insecticida en aerosol para plantas', 'insumo',  0, 3000.00,   6500.00),
    (17, 'Perlita 5 L',             'Aditivo para drenaje de sustratos',  'insumo',   0, 1800.00,   3800.00),
    (18, 'Poda de árboles',         'Hasta 3 árboles medianos',           'servicio', NULL, NULL,  35000.00),
    (19, 'Diseño de jardín',        'Proyecto con plano y listado de especies', 'servicio', NULL, NULL, 120000.00),
    (20, 'Mantenimiento mensual',   'Una visita semanal durante un mes',  'servicio', NULL, NULL,  45000.00),
    (21, 'Trasplante a domicilio',  'Hasta 5 macetas',                    'servicio', NULL, NULL,  15000.00),
    (22, 'Ficus lyrata',            'Maceta n°24',                        'planta',   0, 8500.00,  19500.00),
    (23, 'Guantes de jardinería',   'Par de guantes de nitrilo, talle M', 'insumo',   0, 1200.00,   2800.00);

-- La columna "tipo" de los subtipos toma su valor por DEFAULT
INSERT INTO planta (id_producto, id_tipo_planta, nombre_cientifico, de_interior, nivel_luz, riego_cada_dias) VALUES
    (1,  1, 'Echeveria elegans',      FALSE, 'alta',  10),
    (2,  1, 'Aloe barbadensis',       TRUE,  'media', 14),
    (3,  2, 'Lavandula angustifolia', FALSE, 'alta',   4),
    (4,  2, 'Salvia rosmarinus',      FALSE, 'alta',   5),
    (5,  3, 'Citrus limon',           FALSE, 'alta',   3),
    (6,  4, 'Epipremnum aureum',      TRUE,  'baja',   7),
    (7,  4, 'Monstera deliciosa',     TRUE,  'media',  7),
    (8,  4, 'Dracaena trifasciata',   TRUE,  'baja',  15),
    (9,  5, 'Gardenia jasminoides',   FALSE, 'media',  3),
    (10, 6, 'Petunia x hybrida',      FALSE, 'alta',   2),
    (22, 4, 'Ficus lyrata',           TRUE,  'alta',   7);

INSERT INTO servicio (id_producto, id_tipo_servicio, duracion_estimada_min, a_domicilio) VALUES
    (18, 1, 180, TRUE),
    (19, 2, 240, FALSE),
    (20, 3, 120, TRUE),
    (21, 4,  60, TRUE);

-- -----------------------------------------------------
-- Compras (el total lo calcula el trigger)
-- -----------------------------------------------------

INSERT INTO compra (id_compra, id_proveedor, fecha, forma_de_pago) VALUES
    (1, 1, '2026-08-03', 'transferencia'),
    (2, 1, '2026-08-17', 'transferencia'),
    (3, 2, '2026-08-20', 'credito'),
    (4, 3, '2026-09-01', 'transferencia'),
    (5, 4, '2026-09-10', 'efectivo'),
    (6, 1, '2026-09-28', 'transferencia'),
    (7, 2, '2026-10-05', 'debito'),
    (8, 4, '2026-10-12', 'efectivo');

INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUES
    (1, 1,  30, 1500.00), (1, 2, 20, 2000.00), (1, 6, 15, 2500.00), (1, 7, 8, 7000.00), (1, 8, 12, 3000.00),
    (2, 3,  25, 1800.00), (2, 4, 25, 1200.00), (2, 5,  6, 9000.00), (2, 9, 10, 4000.00),
    (3, 11, 20, 6000.00), (3, 12, 15, 3500.00), (3, 15, 5, 8000.00), (3, 16, 10, 3000.00), (3, 17, 15, 1800.00),
    (4, 13, 50,  600.00), (4, 14, 12, 4500.00),
    (5, 10, 120, 400.00),
    -- reposición con aumento de precio: actualiza precio_compra
    (6, 1,  20, 1650.00), (6, 6, 10, 2700.00), (6, 7, 5, 7400.00),
    -- productos nuevos (22 y 23) que todavía no tienen ventas
    (6, 22,  6, 8500.00),
    (7, 11, 15, 6400.00), (7, 12, 10, 3700.00), (7, 23, 20, 1200.00),
    (8, 10, 80,  420.00);

-- -----------------------------------------------------
-- Ventas (subtotal, total_facturado y stock los actualizan los triggers)
-- id_cliente NULL = consumidor final
-- -----------------------------------------------------

INSERT INTO ticket_venta (id_venta, id_cliente, id_vendedor, fecha, forma_de_pago) VALUES
    (1,  1,    1, '2026-08-05 10:15:00', 'efectivo'),
    (2,  NULL, 2, '2026-08-06 11:30:00', 'efectivo'),
    (3,  2,    1, '2026-08-12 17:05:00', 'debito'),
    (4,  3,    3, '2026-08-21 09:40:00', 'credito'),
    (5,  4,    2, '2026-08-25 16:20:00', 'transferencia'),
    (6,  NULL, 4, '2026-09-02 10:00:00', 'efectivo'),
    (7,  5,    1, '2026-09-05 12:45:00', 'billetera_virtual'),
    (8,  6,    3, '2026-09-12 15:10:00', 'credito'),
    (9,  1,    2, '2026-09-18 18:00:00', 'debito'),
    (10, NULL, 4, '2026-09-21 10:30:00', 'efectivo'),
    (11, 7,    1, '2026-09-30 11:15:00', 'transferencia'),
    (12, 8,    3, '2026-10-03 17:40:00', 'billetera_virtual'),
    (13, 2,    2, '2026-10-08 09:50:00', 'debito'),
    (14, NULL, 1, '2026-10-14 13:20:00', 'efectivo'),
    (15, 9,    4, '2026-10-18 16:00:00', 'credito'),
    (16, 10,   3, '2026-10-20 10:05:00', 'transferencia');

INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario) VALUES
    (1,  1,  3,   3500.00), (1, 13, 3, 1500.00),
    (2,  10, 12,  1000.00),
    (3,  7,  1,  16500.00), (3, 14, 1, 9800.00), (3, 11, 1, 11000.00),
    (4,  5,  2,  22000.00), (4, 12, 1, 7000.00),
    (5,  19, 1, 120000.00),
    (6,  3,  2,   4200.00), (6, 4, 2, 3000.00),
    (7,  6,  2,   6000.00), (7, 8, 1, 7200.00), (7, 13, 3, 1500.00),
    (8,  18, 1,  35000.00), (8, 15, 1, 16000.00),
    (9,  2,  2,   4800.00), (9, 17, 1, 3800.00),
    (10, 10, 24,  1000.00),
    (11, 20, 1,  45000.00), (11, 16, 2, 6500.00), (11, 12, 2, 7000.00),
    (12, 7,  2,  16500.00), (12, 11, 2, 11000.00),
    (13, 9,  2,   9500.00), (13, 21, 1, 15000.00),
    (14, 1,  5,   3500.00), (14, 13, 5, 1500.00),
    (15, 8,  2,   7200.00), (15, 14, 2, 9800.00), (15, 6, 1, 6000.00),
    (16, 20, 1,  45000.00);
