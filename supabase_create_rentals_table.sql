-- Crear tabla de historial de alquileres
-- Ejecutar este SQL en Supabase SQL Editor

CREATE TABLE IF NOT EXISTS rentals (
  id TEXT PRIMARY KEY,
  equipment_id TEXT NOT NULL,
  equipment_name TEXT NOT NULL,
  customer_id TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  location TEXT NOT NULL,
  daily_rate NUMERIC(10, 2) NOT NULL,
  rate_type TEXT NOT NULL CHECK (rate_type IN ('day', 'hour')),
  total_cost NUMERIC(10, 2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_rentals_customer_id ON rentals(customer_id);
CREATE INDEX IF NOT EXISTS idx_rentals_equipment_id ON rentals(equipment_id);
CREATE INDEX IF NOT EXISTS idx_rentals_status ON rentals(status);
CREATE INDEX IF NOT EXISTS idx_rentals_dates ON rentals(start_date, end_date);

-- Comentarios
COMMENT ON TABLE rentals IS 'Historial de alquileres de equipos';
COMMENT ON COLUMN rentals.rate_type IS 'Tipo de tarifa: day (por día) o hour (por hora)';
COMMENT ON COLUMN rentals.status IS 'Estado del alquiler: active (activo), completed (completado), cancelled (cancelado)';

-- Verificar que se creó correctamente
SELECT 
  table_name, 
  column_name, 
  data_type, 
  is_nullable 
FROM information_schema.columns 
WHERE table_name = 'rentals'
ORDER BY ordinal_position;
