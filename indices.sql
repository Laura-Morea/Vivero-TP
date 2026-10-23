-- =====================================================
-- Índices (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de integridad_referencial.sql.
--
-- MySQL ya crea índices para las PK, los UNIQUE (dni, cuit, nombres de
-- catálogos) y las columnas de cada FK. Acá van solo los que sirven a
-- búsquedas y reportes frecuentes que esos índices no cubren.
-- =====================================================

USE vivero;

-- Reportes de ventas y compras por período (ej: ventas del mes)
CREATE INDEX idx_ticket_venta_fecha ON ticket_venta (fecha);
CREATE INDEX idx_compra_fecha       ON compra (fecha);

-- Búsqueda de productos por nombre en el mostrador
CREATE INDEX idx_producto_nombre ON producto (nombre);

-- Listados filtrados por tipo y ordenados por nombre (ej: todas las plantas)
CREATE INDEX idx_producto_tipo_nombre ON producto (tipo, nombre);

-- Búsqueda de personas por apellido y nombre
CREATE INDEX idx_cliente_apellido_nombre  ON cliente (apellido, nombre);
CREATE INDEX idx_vendedor_apellido_nombre ON vendedor (apellido, nombre);
