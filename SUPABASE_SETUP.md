# 🚀 INSTRUCCIONES PARA CONFIGURAR SUPABASE

## ✅ Paso 1: Ejecutar el SQL en Supabase

1. Ve a: https://supabase.com/dashboard/project/ahhhsqswcgtzdgsolybq/editor/sql

2. Copia todo el contenido del archivo **`supabase_schema.sql`**

3. Pégalo en el editor SQL de Supabase

4. Haz clic en **"RUN"** (botón verde en la esquina inferior derecha)

5. Verifica que veas:
   ```
   ✅ Tablas creadas correctamente!
   ✅ total_equipment: 5
   ✅ total_customers: 3  
   ✅ total_maintenance_tasks: 2
   ```

---

## ✅ Paso 2: Verificar las Tablas

Ve a: https://supabase.com/dashboard/project/ahhhsqswcgtzdgsolybq/editor

Deberías ver 3 tablas:
- **equipment** (5 registros)
- **customers** (3 registros)
- **maintenance_tasks** (2 registros)

---

## ✅ Paso 3: Ejecutar la App

```bash
flutter run
```

---

## 🎉 ¿Qué hace la app ahora?

### **Flujo Offline-First:**

1. **Al iniciar**: Carga datos de Supabase → guarda en Hive como caché
2. **Crear/Editar**: Guarda en Supabase → actualiza Hive
3. **Sin internet**: Usa los datos de Hive (offline)
4. **Al reconectar**: Sincroniza automáticamente

### **Beneficios:**

- ✅ Funciona sin internet
- ✅ Sincronización automática
- ✅ Datos persistentes en la nube
- ✅ Caché local rápida
- ✅ Multi-dispositivo (mismo backend)

---

## 🔧 Solución de Problemas

### Error: "Table does not exist"
**Solución**: No ejecutaste el SQL. Ve al Paso 1.

### Error: "Invalid JWT"
**Solución**: Verifica que la `anon key` en `.env` sea correcta.

### Error: "Policy violation"
**Solución**: Las políticas RLS están en modo desarrollo (permisivas).

---

## 📊 Probar la Integración

### **Test 1: Agregar un equipo**
```dart
// La app guardará en Supabase automáticamente
final provider = context.read<EquipmentProvider>();
await provider.addEquipment(Equipment(...));
```

Ve a Supabase Editor y verifica que apareció el nuevo equipo.

### **Test 2: Modo Offline**
1. Ejecuta la app
2. Desconecta el internet
3. Los datos siguen visibles (Hive caché)
4. Reconecta internet
5. Refresca (pull-to-refresh)

---

## 🎯 Próximos Pasos

1. **Autenticación**: Agregar login con email/password
2. **Storage**: Subir fotos de equipos a Supabase Storage
3. **Realtime**: Actualizar datos en tiempo real
4. **Multi-usuario**: Asignar equipos a usuarios específicos

---

**¿Necesitas ayuda?** Avísame cuando ejecutes el SQL y te confirmo si todo está funcionando.
