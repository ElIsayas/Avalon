-- ========================================
-- CORRECCIÓN DE POLÍTICAS RLS PARA PACIENTES Y CITAS
-- ========================================

-- 1. Eliminar políticas existentes que causan conflictos
DROP POLICY IF EXISTS "Users can manage their own pacientes" ON pacientes;
DROP POLICY IF EXISTS "Users can view their own pacientes" ON pacientes;
DROP POLICY IF EXISTS "Users can insert their own pacientes" ON pacientes;
DROP POLICY IF EXISTS "Users can update their own pacientes" ON pacientes;
DROP POLICY IF EXISTS "Users can delete their own pacientes" ON pacientes;

DROP POLICY IF EXISTS "Users can manage their own citas" ON citas;
DROP POLICY IF EXISTS "Users can view their own citas" ON citas;
DROP POLICY IF EXISTS "Users can insert their own citas" ON citas;
DROP POLICY IF EXISTS "Users can update their own citas" ON citas;
DROP POLICY IF EXISTS "Users can delete their own citas" ON citas;

-- 2. Crear políticas simplificadas para pacientes
CREATE POLICY "Enable all operations for authenticated users" ON pacientes
    FOR ALL
    USING (auth.role() IN ('authenticated', 'service_role'))
    WITH CHECK (auth.role() IN ('authenticated', 'service_role'));

-- 3. Crear políticas simplificadas para citas
CREATE POLICY "Enable all operations for authenticated users" ON citas
    FOR ALL
    USING (auth.role() IN ('authenticated', 'service_role'))
    WITH CHECK (auth.role() IN ('authenticated', 'service_role'));

-- 4. Verificar que RLS esté habilitado
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE citas ENABLE ROW LEVEL SECURITY;

-- 5. Dar permisos explícitos al usuario autenticado
-- Para pacientes
GRANT ALL ON pacientes TO authenticated;
GRANT ALL ON pacientes TO service_role;
GRANT SELECT ON pacientes TO anon;

-- Para citas
GRANT ALL ON citas TO authenticated;
GRANT ALL ON citas TO service_role;
GRANT SELECT ON citas TO anon;

-- 6. Política alternativa si la anterior no funciona (basada en licencia)
-- Eliminar esta sección si la política anterior funciona
/*
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON pacientes;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON citas;

CREATE POLICY "Users can manage pacientes by license" ON pacientes
    FOR ALL
    USING (
        licencia_id IN (
            SELECT id FROM licencias 
            WHERE usuario_id = auth.uid()
        )
    )
    WITH CHECK (
        licencia_id IN (
            SELECT id FROM licencias 
            WHERE usuario_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage citas by license" ON citas
    FOR ALL
    USING (
        licencia_id IN (
            SELECT id FROM licencias 
            WHERE usuario_id = auth.uid()
        )
    )
    WITH CHECK (
        licencia_id IN (
            SELECT id FROM licencias 
            WHERE usuario_id = auth.uid()
        )
    );
*/
