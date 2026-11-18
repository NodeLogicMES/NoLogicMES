-- Employees / Operators
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    is_shopfloor_operator BOOLEAN DEFAULT TRUE NOT NULL,
    permissions TEXT[] DEFAULT '{}' NOT NULL,
    password_hash TEXT,
    change_password BOOLEAN DEFAULT TRUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Customers
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    legal_name VARCHAR(150) NOT NULL,
    tax_id VARCHAR(20) UNIQUE NOT NULL,
    contact_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(30),
    sales_rep_id INTEGER REFERENCES employees(id),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Modules (Work Centers / Machine Groups)
CREATE TABLE modules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    customer_id INTEGER REFERENCES customers(id) NOT NULL,
    immutable_specs JSONB,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Product Versions
CREATE TABLE product_versions (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id) NOT NULL,
    version INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    additional_specs JSONB
    notes TEXT
);

-- Work Orders
CREATE TABLE work_orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    product_version_id INTEGER REFERENCES product_versions(id) NOT NULL,
    customer_id INTEGER REFERENCES customers(id) NOT NULL,
    requested_quantity NUMERIC(12, 2) NOT NULL,
    status VARCHAR(30) DEFAULT 'CREATED' NOT NULL,
    scheduled_start_at TIMESTAMP WITH TIME ZONE,
    scheduled_end_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Machines
CREATE TABLE machines (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    module_id INTEGER REFERENCES modules(id),
    type VARCHAR(50) NOT NULL,
    status VARCHAR(30) DEFAULT 'OPERATIONAL' NOT NULL,
    active_work JSONB DEFAULT '[]'::jsonb NOT NULL, -- Ej: [{"orden_id": 108, "nodo_id": 2}]
    queued_work JSONB DEFAULT '[]'::jsonb NOT NULL, -- Ej: [{"orden_id": 108, "nodo_id": 2}]
    required_permission VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Capabilities
CREATE TABLE capabilities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    machine_id INTEGER REFERENCES machines(id) ON DELETE CASCADE,
    module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,

    CONSTRAINT chk_exclusive_resource CHECK (
        (machine_id IS NOT NULL AND module_id IS NULL) OR 
        (machine_id IS NULL AND module_id IS NOT NULL)
    ),

    UNIQUE (name, machine_id, module_id)
);

-- Nodes (Process Routing Steps)
CREATE TABLE nodes (
    id SERIAL PRIMARY KEY,
    capability_id INTEGER REFERENCES capabilities(id) NOT NULL,
    product_version_id INTEGER REFERENCES product_versions(id) NOT NULL,
    tools JSONB,
    materials JSONB,
    input_parts JSONB,
    output_parts JSONB,
    notes TEXT
);

-- Tools & Dies (Tooling)
CREATE TABLE tools (
    id SERIAL PRIMARY KEY,
    external_code VARCHAR(50),
    tool_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count INTEGER DEFAULT 0 NOT NULL,
    max_lifespan INTEGER,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Raw Materials & Consumables
CREATE TABLE materials (
    id SERIAL PRIMARY KEY,
    material_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(50) NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL,
    current_stock NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    min_stock NUMERIC(12, 2) DEFAULT 0.00 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Parts & Components
CREATE TABLE parts (
    id SERIAL PRIMARY KEY,
    part_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(50) NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL,
    current_stock INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Production Logs (Immutable)
CREATE TABLE production_logs (
    id SERIAL PRIMARY KEY,
    work_order_id INTEGER REFERENCES work_orders(id) NOT NULL,
    machine_id INTEGER REFERENCES machines(id) NOT NULL,
    node_id INTEGER REFERENCES nodes(id) NOT NULL,
    employee_id INTEGER REFERENCES employees(id) NOT NULL,
    tool_id INTEGER REFERENCES tools(id),
    event_type VARCHAR(50) NOT NULL,
    produced_units INTEGER DEFAULT 0 NOT NULL,
    defective_units INTEGER DEFAULT 0 NOT NULL,
    process_parameters JSONB,
    is_completed BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Material Stock Movements (Immutable)
CREATE TABLE material_stock_logs (
    id SERIAL PRIMARY KEY,
    material_id INTEGER REFERENCES materials(id) NOT NULL,
    production_log_id INTEGER REFERENCES production_logs(id),
    movement_type VARCHAR(30) NOT NULL,
    quantity NUMERIC(12, 2) NOT NULL,
    source_batch VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Part Stock Movements (Immutable)
CREATE TABLE part_stock_logs (
    id SERIAL PRIMARY KEY,
    part_id INTEGER REFERENCES parts(id) NOT NULL,
    production_log_id INTEGER REFERENCES production_logs(id),
    movement_type VARCHAR(30) NOT NULL,
    quantity NUMERIC(12, 2) NOT NULL,
    source_batch VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

