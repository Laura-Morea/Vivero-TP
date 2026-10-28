# Sistema de gestión de vivero

Proyecto final de Estructuras y Base de Datos — INSPT, Comisión 2.603 (2026).
Grupo 3: Álvarez Varone, Guido Martín · Deluca, Nicolás Andrés · Morea, Laura Elena.

Base de datos transaccional para un vivero: venta de plantas e insumos,
compras a proveedores y control de stock. Los servicios (poda, mantenimiento,
etc.) quedan fuera del alcance.

## Requisitos

- MySQL 8.0.16 o superior (por los `CHECK`). Probado con MySQL 8.4.
- Cliente `mysql` de línea de comandos o MySQL Workbench.

## Estructura

```
Informe.docx                      Especificaciones técnicas (informe de la entrega)
Diagramas/
  DER_Vivero.drawio / .png        Diagrama entidad-relación (modelo conceptual)
  EER_tablas_Vivero.drawio / .png Modelo lógico: tablas, columnas, claves y relaciones
Scripts/
  schema.sql                      Base y tablas con PK, NOT NULL, DEFAULT y UNIQUE
  integridad_referencial.sql      Restricciones con nombre: CHECK y claves foráneas
  indices.sql                     Índices para búsquedas y reportes
  triggers.sql                    Stock, totales y validaciones de negocio
  datos.sql                       Datos de prueba
  queries.sql                     Consultas de prueba y pruebas negativas
```

El informe, los diagramas y los scripts describen el mismo modelo. Si se cambia
uno, hay que actualizar los otros (y volver a exportar los PNG desde drawio).

## Modelo

| Tabla | Qué guarda |
|---|---|
| `vendedor`, `cliente`, `proveedor` | Personas y empresas con las que opera el vivero. |
| `producto` | Supertipo: stock, stock mínimo, precio de compra y de venta, y si está activo. |
| `planta`, `insumo` | Subtipos de producto, cada uno con su PK y una FK `UNIQUE` a `producto`. |
| `venta`, `detalle_venta` | Cabecera y renglones de cada venta. |
| `compra`, `detalle_compra` | Cabecera y renglones de cada compra a un proveedor. |

## Cómo cargar la base

Los scripts se ejecutan **en este orden** (`schema.sql` **borra la base `vivero`
si ya existe**):

```
schema.sql → integridad_referencial.sql → indices.sql → triggers.sql → datos.sql
```

Los datos van al final porque los triggers son los que calculan el stock y los totales.

```sh
cd Scripts
cat schema.sql integridad_referencial.sql indices.sql triggers.sql datos.sql | mysql -u <usuario> -p
```

### Script único (para la entrega)

`vivero_completo.sql` junta todos los scripts en uno solo. No se versiona: se
genera cuando hace falta con:

```sh
cd Scripts
cat schema.sql integridad_referencial.sql indices.sql triggers.sql datos.sql > vivero_completo.sql
```

y se ejecuta con `mysql -u <usuario> -p < vivero_completo.sql`. En Workbench:
*File → Open SQL Script* y ejecutar todo (⚡).

## Cómo correr las consultas de prueba

```sh
cd Scripts
mysql --force -vvv -t -u <usuario> -p < queries.sql
```

`-vvv -t` muestra cada sentencia junto con su resultado en forma de tabla.

- **Consultas 1 a 12**: reportes de top de vendedores, productos y clientes,
  producto más facturado por tipo, ventas por mes, formas de pago, stock
  crítico, márgenes, compras por proveedor, productos sin ventas, detalle de
  una venta e historial de compras por cliente.
- **Pruebas negativas N1 a N20**: cada sentencia **debe fallar**. El comentario
  de cada una indica qué restricción o trigger la frena; MySQL escribe el
  mensaje completo (por ejemplo `Check constraint 'chk_planta_riego' is violated.`).
  Hace falta `--force` para que el cliente siga después de cada error. Van
  dentro de una transacción que se deshace al final, así que no modifican los datos.

## Decisiones de diseño

- **Producto como supertipo.** `producto` guarda los datos comunes; el nombre y
  los atributos propios están en `planta` o `insumo` (relación 1:1 con FK
  `UNIQUE`). Las ventas y las compras apuntan solo a `producto`. Un trigger
  impide que un producto sea planta e insumo a la vez.
- **Precios históricos.** Cada detalle de venta o de compra guarda el precio
  unitario de ese momento. `producto.precio_compra` refleja la última compra
  y queda en `NULL` mientras el producto no tenga compras.
- **Un producto por renglón.** Los detalles tienen PK propia, pero
  `(id_venta, id_producto)` y `(id_compra, id_producto)` son `UNIQUE`: si se
  llevan más unidades, se aumenta la cantidad.
- **Stock automático.** Las compras suman y las ventas restan. No se puede vender
  sin stock ni un producto dado de baja, y anular una compra cuyo stock ya se
  vendió falla.
- **Baja lógica.** Un producto con ventas o compras no se puede borrar (FK
  `RESTRICT`); se lo da de baja con `activo = FALSE`.
- **Stock crítico.** Cada producto tiene su `stock_minimo`; la consulta 7 lista
  los activos que están por debajo.
- **Consumidor final.** Toda venta tiene cliente; las ventas a quien no se
  identifica van al cliente 1, "Consumidor final". Es el único id fijo de los
  datos de prueba: el resto los asigna `AUTO_INCREMENT`.
- **Cascadas y triggers.** Borrar una venta o compra borra sus detalles por
  `ON DELETE CASCADE`. Como en MySQL las cascadas no disparan triggers,
  `trg_venta_bd` y `trg_compra_bd` ajustan el stock antes del borrado.
- **Fechas.** Una venta o compra no puede tener fecha futura. Un `CHECK` no
  admite `CURRENT_DATE`, así que lo controlan triggers.
- **Dominios.** DNI de vendedor solo dígitos; DNI de cliente admite letras
  (pasaportes); CUIT de 11 dígitos sin guiones; teléfonos con `+` inicial
  opcional. Se validan con `CHECK`.

### Limitaciones conocidas

- La base no puede forzar que todo producto tenga su fila en `planta` o en
  `insumo`.
- Tampoco puede forzar que una venta o una compra tengan al menos un detalle.
