# Sistema de gestión de vivero

Proyecto final de Estructuras y Base de Datos — INSPT, Comisión 2.603 (2026).

Base de datos transaccional para un vivero: venta de plantas, insumos y
servicios, compras a proveedores y control de stock.

## Requisitos

- MySQL 8.0.16 o superior (por los `CHECK`). Probado con MySQL 8.4.
- Cliente `mysql` de línea de comandos o MySQL Workbench.

## Archivos

| Archivo | Contenido |
|---|---|
| `schema.sql` | Crea la base `vivero` y sus tablas con PK, `NOT NULL`, `DEFAULT`, `UNIQUE` y `CHECK`. **Borra la base si ya existe.** |
| `integridad_referencial.sql` | Claves foráneas (`ALTER TABLE ... ADD FOREIGN KEY`), todas con `RESTRICT`. |
| `indices.sql` | Índices para búsquedas y reportes frecuentes. |
| `triggers.sql` | Subtotales, totales, actualización de stock y validaciones de negocio. |
| `datos.sql` | Datos de prueba: clientes, vendedores, proveedores, 23 productos, compras y ventas. |
| `queries.sql` | Consultas de prueba y, en una sección aparte, pruebas negativas. |
| `DER_Vivero.drawio` | Diagrama entidad-relación. |

## Cómo cargar la base

Los scripts se ejecutan **en este orden**:

```
schema.sql → integridad_referencial.sql → indices.sql → triggers.sql → datos.sql
```

Los datos van al final porque los triggers son los que calculan el stock y los totales.

### Script único (para la entrega)

`vivero_completo.sql` junta todos los scripts en uno solo. No se versiona: se
genera cuando hace falta con:

```sh
cat schema.sql integridad_referencial.sql indices.sql triggers.sql datos.sql > vivero_completo.sql
```

y se ejecuta con:

```sh
mysql -u <usuario> -p < vivero_completo.sql
```

En Workbench: *File → Open SQL Script* y ejecutar todo (⚡).

## Cómo correr las consultas de prueba

```sh
mysql --force -u <usuario> -p < queries.sql
```

- **Consultas 1 a 15**: reportes (top de vendedores y productos, ventas por mes,
  márgenes, stock a reponer, etc.) y controles de consistencia de los triggers.
  La 15 simula una venta dentro de una transacción y la deshace con `ROLLBACK`.
- **Pruebas negativas N1 a N16**: cada sentencia **debe fallar**. El comentario
  de cada una indica el error esperado. Hace falta `--force` para que el cliente
  siga después de cada error. Van dentro de una transacción que se deshace al
  final, así que no modifican los datos.

## Decisiones de diseño

- **Producto como supertipo.** Plantas, insumos y servicios están en la tabla
  `producto`, con una columna `tipo`. Las ventas y las compras apuntan solo a
  `producto`, sin importar de qué tipo sea.
- **Subtipos solo con datos propios.** `planta` y `servicio` guardan sus
  atributos específicos. Los insumos no tienen tabla propia. Una FK compuesta
  `(id_producto, tipo)` impide, por ejemplo, cargar como planta un producto que
  es un insumo.
- **Los servicios no tienen stock ni precio de compra**, y no se pueden comprar.
- **Precios históricos.** Cada detalle de venta o de compra guarda el precio
  unitario de ese momento. `producto.precio_compra` refleja la última compra.
- **Stock automático.** Las compras suman y las ventas restan. No se puede vender
  sin stock, y anular una compra cuyo stock ya se vendió falla.
- **Consumidor final.** Una venta puede no tener cliente (`id_cliente` NULL).
- **Sin borrado en cascada.** En MySQL las cascadas no disparan triggers, así que
  para anular una venta o una compra primero se borran sus detalles.

### Limitaciones conocidas

- La base no puede forzar que un producto de tipo `planta` o `servicio` tenga su
  fila en la tabla del subtipo.
- Tampoco puede forzar que una venta o una compra tengan al menos un detalle.
