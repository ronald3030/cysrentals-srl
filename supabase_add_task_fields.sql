-- Agregar campos nuevos a la tabla maintenance_tasks
-- Ejecutar este SQL en Supabase SQL Editor

-- Agregar tipo de tarea
ALTER TABLE maintenance_tasks 
ADD COLUMN IF NOT EXISTS task_type TEXT NOT NULL DEFAULT 'maintenance' CHECK (task_type IN ('maintenance', 'routine', 'repair', 'inspection', 'upgrade'));

-- Agregar fecha de entrega
ALTER TABLE maintenance_tasks 
ADD COLUMN IF NOT EXISTS delivery_date TIMESTAMPTZ;

-- Agregar fecha de finalización
ALTER TABLE maintenance_tasks 
ADD COLUMN IF NOT EXISTS finish_date TIMESTAMPTZ;

-- Comentarios
COMMENT ON COLUMN maintenance_tasks.task_type IS 'Tipo de tarea: maintenance (Mantenimiento), routine (Rutina), repair (Reparación), inspection (Inspección), upgrade (Actualización)';
COMMENT ON COLUMN maintenance_tasks.delivery_date IS 'Fecha de entrega del equipo al cliente';
COMMENT ON COLUMN maintenance_tasks.finish_date IS 'Fecha de finalización de la tarea';

-- Verificar que se agregaron correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'maintenance_tasks' 
AND column_name IN ('task_type', 'delivery_date', 'finish_date')
ORDER BY column_name;
