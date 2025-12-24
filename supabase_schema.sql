-- ===========================================
-- C&S RENTALS SRL - SUPABASE DATABASE SCHEMA
-- ===========================================

-- 1. TABLA: equipment (Equipos)
CREATE TABLE IF NOT EXISTS equipment (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('available', 'rented', 'maintenance', 'outOfService')),
  description TEXT NOT NULL,
  customer TEXT,
  location TEXT,
  rental_start_date TIMESTAMPTZ,
  rental_end_date TIMESTAMPTZ,
  daily_rate NUMERIC(10, 2),
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para equipment
CREATE INDEX IF NOT EXISTS idx_equipment_status ON equipment(status);
CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category);
CREATE INDEX IF NOT EXISTS idx_equipment_customer ON equipment(customer);

-- 2. TABLA: customers (Clientes)
CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  email TEXT,
  contact_person TEXT,
  assigned_equipment_count INTEGER DEFAULT 0,
  total_rentals INTEGER DEFAULT 0,
  last_rental_date TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'suspended')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para customers
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);

-- 3. TABLA: maintenance_tasks (Tareas de Mantenimiento)
CREATE TABLE IF NOT EXISTS maintenance_tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  equipment_id TEXT NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
  equipment_name TEXT NOT NULL,
  priority TEXT NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
  status TEXT NOT NULL CHECK (status IN ('open', 'inProgress', 'completed')),
  scheduled_date TIMESTAMPTZ NOT NULL,
  assigned_technician TEXT NOT NULL,
  estimated_duration INTEGER NOT NULL, -- en minutos
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para maintenance_tasks
CREATE INDEX IF NOT EXISTS idx_maintenance_status ON maintenance_tasks(status);
CREATE INDEX IF NOT EXISTS idx_maintenance_priority ON maintenance_tasks(priority);
CREATE INDEX IF NOT EXISTS idx_maintenance_equipment ON maintenance_tasks(equipment_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_scheduled ON maintenance_tasks(scheduled_date);

-- ===========================================
-- TRIGGERS PARA UPDATED_AT AUTOMÁTICO
-- ===========================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para equipment
DROP TRIGGER IF EXISTS update_equipment_updated_at ON equipment;
CREATE TRIGGER update_equipment_updated_at
  BEFORE UPDATE ON equipment
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para customers
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para maintenance_tasks
DROP TRIGGER IF EXISTS update_maintenance_tasks_updated_at ON maintenance_tasks;
CREATE TRIGGER update_maintenance_tasks_updated_at
  BEFORE UPDATE ON maintenance_tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- ROW LEVEL SECURITY (RLS) - DESARROLLO
-- ===========================================
-- IMPORTANTE: Para desarrollo dejamos todo abierto
-- En producción debes configurar políticas apropiadas

ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para desarrollo (CAMBIAR EN PRODUCCIÓN)
CREATE POLICY "Allow all for equipment" ON equipment FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for customers" ON customers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for maintenance_tasks" ON maintenance_tasks FOR ALL USING (true) WITH CHECK (true);

-- ===========================================
-- DATOS DE EJEMPLO (OPCIONAL)
-- ===========================================

-- Insertar equipos de ejemplo
INSERT INTO equipment (id, name, category, status, description, daily_rate) VALUES
('E001', 'Excavadora CAT 320DL', 'Maquinaria Pesada', 'available', 'Excavadora hidráulica de 20 toneladas para proyectos de construcción pesada', 5000.00),
('E002', 'Mezcladora de Concreto 350L', 'Construcción', 'available', 'Mezcladora portátil de concreto con capacidad de 350 litros', 800.00),
('E003', 'Motosierra STIHL MS 381', 'Jardinería', 'maintenance', 'Motosierra profesional de 5.9 HP para corte de árboles grandes', 300.00),
('E004', 'Taladro de Impacto DeWalt 20V', 'Herramientas Eléctricas', 'available', 'Taladro percutor inalámbrico de alto rendimiento con batería de litio', 150.00),
('E005', 'Arnés de Seguridad Completo', 'Equipo de Seguridad', 'available', 'Kit completo de arnés de seguridad con casco y accesorios', 200.00)
ON CONFLICT (id) DO NOTHING;

-- Insertar clientes de ejemplo
INSERT INTO customers (id, name, phone, address, status, email, total_rentals, last_rental_date) VALUES
('C001', 'Constructora Caribena SRL', '+1 (809) 234-5678', 'Av. 27 de Febrero #142, Ensanche Naco, Santo Domingo', 'active', 'contacto@caribena.com.do', 24, NOW() - INTERVAL '2 days'),
('C002', 'Ingeniería del Cibao', '+1 (829) 567-8901', 'Calle Real #89, Centro Histórico, Santiago de los Caballeros', 'active', 'info@ingcibao.com', 18, NOW() - INTERVAL '5 days'),
('C003', 'Paisajismo Tropical RD', '+1 (849) 123-4567', 'Av. Abraham Lincoln #456, Piantini, Santo Domingo', 'inactive', NULL, 12, NOW() - INTERVAL '30 days')
ON CONFLICT (id) DO NOTHING;

-- Insertar tareas de mantenimiento de ejemplo
INSERT INTO maintenance_tasks (id, title, description, equipment_id, equipment_name, priority, status, scheduled_date, assigned_technician, estimated_duration) VALUES
('M001', 'Inspección de 500 horas - Excavadora CAT', 'Mantenimiento preventivo programado: cambio de aceite, filtros y revisión general del sistema hidráulico', 'E001', 'Excavadora CAT 320DL', 'high', 'open', NOW() + INTERVAL '2 days', 'Juan Pérez', 240),
('M002', 'Afilado de cadena motosierra', 'Mantenimiento rutinario: afilar cadena, limpiar filtro de aire y revisar sistema de lubricación', 'E003', 'Motosierra STIHL MS 381', 'high', 'open', NOW(), 'Luis Rodríguez', 60)
ON CONFLICT (id) DO NOTHING;

-- ===========================================
-- VERIFICACIÓN
-- ===========================================

SELECT 'Tablas creadas correctamente!' as status;
SELECT COUNT(*) as total_equipment FROM equipment;
SELECT COUNT(*) as total_customers FROM customers;
SELECT COUNT(*) as total_maintenance_tasks FROM maintenance_tasks;
