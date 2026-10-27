-- =====================================================
-- Índices (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de integridad_referencial.sql.
--
-- MySQL ya crea índices para las PK, los UNIQUE (dni, cuit, id_producto
-- de los subtipos, (id_venta, id_producto) de los detalles) y las
-- columnas de cada FK. Acá van solo los que sirven a búsquedas y
-- reportes frecuentes que esos índices no cubren.
-- =====================================================

USE vivero;

-- Reportes de ventas y compras por período (ej: ventas del mes)
CREATE INDEX idx_venta_fecha  ON venta (fecha);
CREATE INDEX idx_compra_fecha ON compra (fecha);

-- Búsqueda de productos por nombre (RNF-01)
CREATE INDEX idx_planta_nombre ON planta (nombre);
CREATE INDEX idx_insumo_nombre ON insumo (nombre);

-- Listados de plantas por categoría (RNF-01)
CREATE INDEX idx_planta_tipo_nombre ON planta (tipo_planta, nombre);

-- Búsqueda de personas por apellido y nombre
CREATE INDEX idx_cliente_apellido_nombre  ON cliente (apellido, nombre);
CREATE INDEX idx_vendedor_apellido_nombre ON vendedor (apellido, nombre);
