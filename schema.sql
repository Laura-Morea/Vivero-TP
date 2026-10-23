-- =====================================================
-- Sistema de gestión de vivero - Schema (MySQL 8.0.16+)
-- Basado en DER_Vivero.drawio, con productos, plantas e insumos
-- y servicios modelados como especialización de "producto".
-- Las líneas marcadas con "AJUSTE" se apartan del DER original.
--
-- Este archivo define las tablas con sus restricciones de dominio y de
-- entidad (PK, NOT NULL, DEFAULT, UNIQUE, CHECK). Las claves foráneas
-- están en integridad_referencial.sql y se ejecutan después.
-- =====================================================

DROP DATABASE IF EXISTS vivero;
CREATE DATABASE vivero CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE vivero;

-- -----------------------------------------------------
-- Entidades independientes
-- -----------------------------------------------------

CREATE TABLE cliente (
    id_cliente  INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    apellido    VARCHAR(50) NOT NULL,
    telefono    VARCHAR(20),
    dni         VARCHAR(15) NULL UNIQUE                -- opcional: el cliente puede no darlo
);

CREATE TABLE vendedor (
    id_vendedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL,
    apellido    VARCHAR(50)  NOT NULL,
    telefono    VARCHAR(20),
    direccion   VARCHAR(100),
    mail        VARCHAR(100),
    dni         VARCHAR(15)  NOT NULL UNIQUE
);

CREATE TABLE proveedor (
    id_proveedor   INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empresa VARCHAR(100) NOT NULL,
    telefono       VARCHAR(20),
    cuit           VARCHAR(13)  NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Catálogos de tipos
-- -----------------------------------------------------

CREATE TABLE tipo_planta (
    id_tipo_planta INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(50) NOT NULL UNIQUE,    -- ej: suculenta, frutal, aromática
    descripcion    VARCHAR(255)
);

CREATE TABLE tipo_servicio (
    id_tipo_servicio INT AUTO_INCREMENT PRIMARY KEY,
    nombre           VARCHAR(50) NOT NULL UNIQUE,  -- ej: poda, diseño de jardín, mantenimiento
    descripcion      VARCHAR(255)
);

-- -----------------------------------------------------
-- Producto (supertipo): plantas, insumos y servicios
-- -----------------------------------------------------
-- AJUSTE: "inventario" pasa a llamarse "producto" y se agrega la columna "tipo".
-- Los insumos no tienen tabla propia: no tienen atributos específicos.
-- Los servicios no manejan stock ni precio de compra (quedan en NULL).

CREATE TABLE producto (
    id_producto    INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(100)  NOT NULL,
    descripcion    VARCHAR(255),
    tipo           VARCHAR(10)   NOT NULL,
    cantidad_stock INT           NULL,
    precio_compra  DECIMAL(10,2) NULL,
    precio_venta   DECIMAL(10,2) NOT NULL,
    -- necesario para que los subtipos puedan referenciar (id_producto, tipo)
    UNIQUE KEY uq_producto_tipo (id_producto, tipo),
    CONSTRAINT chk_producto_tipo
        CHECK (tipo IN ('planta', 'insumo', 'servicio')),
    CONSTRAINT chk_producto_stock_segun_tipo CHECK (
        (tipo = 'servicio' AND cantidad_stock IS NULL AND precio_compra IS NULL)
        OR
        (tipo <> 'servicio' AND cantidad_stock IS NOT NULL AND precio_compra IS NOT NULL)
    ),
    CONSTRAINT chk_producto_stock_no_negativo CHECK (cantidad_stock >= 0),
    CONSTRAINT chk_producto_precios CHECK (precio_venta >= 0 AND (precio_compra IS NULL OR precio_compra >= 0))
);

-- -----------------------------------------------------
-- Subtipos (solo los que tienen datos propios)
-- La FK compuesta (id_producto, tipo) garantiza que una fila de "planta"
-- solo pueda apuntar a un producto cuyo tipo sea 'planta' (idem servicio).
-- -----------------------------------------------------

CREATE TABLE planta (
    id_producto      INT PRIMARY KEY,
    tipo             VARCHAR(10) NOT NULL DEFAULT 'planta',
    id_tipo_planta   INT         NOT NULL,
    nombre_cientifico VARCHAR(100),
    de_interior      BOOLEAN     NOT NULL DEFAULT FALSE,
    nivel_luz        ENUM('baja', 'media', 'alta'),
    riego_cada_dias  SMALLINT,
    CONSTRAINT chk_planta_tipo CHECK (tipo = 'planta')
);

CREATE TABLE servicio (
    id_producto          INT PRIMARY KEY,
    tipo                 VARCHAR(10) NOT NULL DEFAULT 'servicio',
    id_tipo_servicio     INT         NOT NULL,
    duracion_estimada_min INT,
    a_domicilio          BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_servicio_tipo CHECK (tipo = 'servicio')
);

-- -----------------------------------------------------
-- Circuito de reposición
-- -----------------------------------------------------

CREATE TABLE compra (
    id_compra     INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor  INT NOT NULL,                           -- relación "provee"
    fecha         DATE NOT NULL,
    total         DECIMAL(12,2) NOT NULL DEFAULT 0,       -- derivado (suma de subtotales)
    forma_de_pago ENUM('efectivo','debito','credito','transferencia','billetera_virtual') NOT NULL
);

-- Relación N:M compra - producto
-- Nota: solo se compran productos con stock (plantas e insumos), no servicios.
-- Esa regla no se puede forzar con un CHECK; la valida trg_detalle_compra_bi.
CREATE TABLE detalle_compra (
    id_compra       INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,               -- AJUSTE: precio al momento de la compra
    subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0,     -- derivado: lo calcula el trigger (cantidad * precio_unitario)
    PRIMARY KEY (id_compra, id_producto),
    CONSTRAINT chk_dcompra_cantidad CHECK (cantidad > 0)
);

-- -----------------------------------------------------
-- Circuito de venta
-- -----------------------------------------------------

CREATE TABLE venta (
    id_venta        INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente      INT NULL,                             -- relación "recibe"; NULL = consumidor final
    id_vendedor     INT NOT NULL,                         -- relación "realiza"
    fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_facturado DECIMAL(12,2) NOT NULL DEFAULT 0,     -- derivado (suma de subtotales)
    forma_de_pago   ENUM('efectivo','debito','credito','transferencia','billetera_virtual') NOT NULL
);

-- Relación N:M venta - producto (incluye plantas, insumos y servicios)
CREATE TABLE detalle_venta (
    id_venta        INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,               -- AJUSTE: precio al momento de la venta
    subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0,     -- derivado: lo calcula el trigger (cantidad * precio_unitario)
    PRIMARY KEY (id_venta, id_producto),
    CONSTRAINT chk_dventa_cantidad CHECK (cantidad > 0)
);
