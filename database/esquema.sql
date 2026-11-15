-- Empleados / Operarios
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    codigo_empleado VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    puesto VARCHAR(50) NOT NULL,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario VARCHAR(255)
);

-- Clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    codigo_cliente VARCHAR(50) UNIQUE NOT NULL,
    nombre_fiscal VARCHAR(150) NOT NULL,
    cif_nif VARCHAR(20) UNIQUE NOT NULL,
    contacto VARCHAR(100),
    email VARCHAR(100),
    telefono VARCHAR(30),
    comercial INTEGER REFERENCES empleados(id),
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

-- Módulos
CREATE TABLE modulos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Máquinas
CREATE TABLE maquinas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    modulo_id INTEGER REFERENCES modulos(id)
    tipo VARCHAR(50) NOT NULL,
    estado VARCHAR(30) DEFAULT 'OPERATIVA' NOT NULL,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

-- Capacidad de trabajo
CREATE TABLE capacidades (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    maquina_id INTEGER REFERENCES maquinas(id) ON DELETE CASCADE,
    modulo_id INTEGER REFERENCES modulos(id) ON DELETE CASCADE,

    CONSTRAINT chk_recurso_exclusivo CHECK (
        (maquina_id IS NOT NULL AND modulo_id IS NULL) OR 
        (maquina_id IS NULL AND modulo_id IS NOT NULL)
    ),

    UNIQUE (nombre, maquina_id, modulo_id)
    
);

-- Herramientas y Clichés
CREATE TABLE herramientas (
    id SERIAL PRIMARY KEY,
    codigo_externo VARCHAR(50),
    codigo_herramienta VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    fecha_entrada DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_ultimo_uso TIMESTAMP WITH TIME ZONE,
    cantidad_uso INTEGER DEFAULT 0 NOT NULL,
    vida_util_maxima INTEGER,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

-- Materias Primas y Componentes
CREATE TABLE materiales (
    id SERIAL PRIMARY KEY,
    codigo_material VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL,
    stock_actual NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    stock_minimo NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);


-- Productos
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    cliente_id INTEGER REFERENCES clientes(id) NOT NULL,
    caracteristicas_inmutables JSONB, -- Aqui entrarian caracteristicas que si se tienen que cambiar ya no es el mismo producto, es otro producto, como las medida de una bolsa
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

CREATE TABLE version_producto (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER REFERENCES productos(id) NOT NULL,
    version INTEGER NOT NULL,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    caracteristicas_adicionales JSONB
);


-- Piezas
CREATE TABLE piezas (
    id SERIAL PRIMARY KEY,
    codigo_material VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL,
    stock_actual INTEGER DEFAULT 0 NOT NULL,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

-- Nodos
CREATE TABLE nodos (
    id SERIAL PRIMARY KEY,
    capacidad_id INTEGER REFERENCES capacidades(id) NOT NULL,
    version_producto_id INTEGER REFERENCES version_producto(id) NOT NULL,
    herramientas JSONB, -- Lista de materiales no consumibles como troqueles y clichés.
    materiales JSONB, -- Lista de materiales consumibles como pegamentos, tintas, peliculas.
    piezas_entrada JSONB, -- Lista de piezas que entran con cantidades
    piezas_salida JSONB, -- Lista de piezas que salen con cantidades
    comentario TEXT
);


-- Órdenes de Trabajo / Producción
CREATE TABLE ordenes (
    id SERIAL PRIMARY KEY,
    numero_orden VARCHAR(50) UNIQUE NOT NULL,
    version_producto_id INTEGER REFERENCES version_producto(id) NOT NULL,
    cliente_id INTEGER REFERENCES clientes(id) NOT NULL,
    cantidad_solicitada NUMERIC(12, 2) NOT NULL,
    estado VARCHAR(30) DEFAULT 'CREADA' NOT NULL,
    fecha_inicio_prevista TIMESTAMP WITH TIME ZONE,
    fecha_fin_prevista TIMESTAMP WITH TIME ZONE,
    habilitado BOOLEAN DEFAULT TRUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

-- Logs de Producción (Registro inmutable paso a paso de lo que ocurre en máquina)
CREATE TABLE production_logs (
    id SERIAL PRIMARY KEY,
    orden_id INTEGER REFERENCES ordenes(id) NOT NULL,
    maquina_id INTEGER REFERENCES maquinas(id) NOT NULL,
    nodo_id INTEGER REFERENCES nodos(id) NOT NULL,
    empleado_id INTEGER REFERENCES empleados(id) NOT NULL,
    herramienta_id INTEGER REFERENCES herramientas(id),
    evento VARCHAR(50) NOT NULL,
    unidades_producidas INTEGER DEFAULT 0 NOT NULL,
    unidades_defectuosas INTEGER DEFAULT 0 NOT NULL,
    parametros_proceso JSONB,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

-- Movimientos de Materiales
CREATE TABLE stock_materiales_logs (
    id SERIAL PRIMARY KEY,
    material_id INTEGER REFERENCES materiales(id) NOT NULL,
    production_log_id INTEGER REFERENCES production_logs(id),
    tipo_movimiento VARCHAR(30) NOT NULL,
    cantidad NUMERIC(12, 2) NOT NULL,
    lote_origen VARCHAR(100),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

-- Movimientos de Piezas
CREATE TABLE log_stock_piezas_logs (
    id SERIAL PRIMARY KEY,
    pieza INTEGER REFERENCES piezas(id) NOT NULL,
    production_log_id INTEGER REFERENCES production_logs(id),
    tipo_movimiento VARCHAR(30) NOT NULL,
    cantidad NUMERIC(12, 2) NOT NULL,
    lote_origen VARCHAR(100),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    comentario TEXT
);

