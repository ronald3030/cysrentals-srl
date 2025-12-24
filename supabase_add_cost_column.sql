-- Agregar columna cost a la tabla maintenance_tasks
-- Ejecutar este SQL en Supabase SQL Editor

ALTER TABLE maintenance_tasks 
ADD COLUMN IF NOT EXISTS cost NUMERIC(10, 2);

COMMENT ON COLUMN maintenance_tasks.cost IS 'Costo total del mantenimiento incluyendo piezas y mano de obra';

-- Verificar que se agregó correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'maintenance_tasks' 
AND column_name = 'cost';
