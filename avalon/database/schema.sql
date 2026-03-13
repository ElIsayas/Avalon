-- =============================================
-- Sistema de Autenticación por Licencias con HWID
-- =============================================

-- Tabla de Licencias
CREATE TABLE IF NOT EXISTS licencias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT UNIQUE NOT NULL,
    usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    hwid TEXT,
    activa BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_activacion TIMESTAMP WITH TIME ZONE,
    fecha_expiracion TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_licencias_license_key ON licencias(license_key);
CREATE INDEX IF NOT EXISTS idx_licencias_activa ON licencias(activa);
CREATE INDEX IF NOT EXISTS idx_licencias_hwid ON licencias(hwid);
CREATE INDEX IF NOT EXISTS idx_licencias_usuario_id ON licencias(usuario_id);
CREATE INDEX IF NOT EXISTS idx_licencias_disponibles ON licencias(usuario_id) WHERE usuario_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_activo ON usuarios(activo);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_licencias_updated_at BEFORE UPDATE
    ON licencias FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE
    ON usuarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para generar licencias
CREATE OR REPLACE FUNCTION generar_licencia()
RETURNS TEXT AS $$
DECLARE
    license_key TEXT;
    parte1 TEXT;
    parte2 TEXT;
    parte3 TEXT;
    parte4 TEXT;
BEGIN
    LOOP
        -- Generar 4 partes de 4 caracteres cada una
        parte1 := upper(substring(encode(gen_random_bytes(16), 'hex'), 1, 4));
        parte2 := upper(substring(encode(gen_random_bytes(16), 'hex'), 5, 4));
        parte3 := upper(substring(encode(gen_random_bytes(16), 'hex'), 9, 4));
        parte4 := upper(substring(encode(gen_random_bytes(16), 'hex'), 13, 4));
        
        license_key := parte1 || '-' || parte2 || '-' || parte3 || '-' || parte4;
        
        -- Verificar que no exista
        IF NOT EXISTS (SELECT 1 FROM licencias WHERE license_key = license_key) THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN license_key;
END;
$$ LANGUAGE plpgsql;

-- Función para crear usuario con licencia automática
CREATE OR REPLACE FUNCTION crear_usuario_con_licencia(
    p_nombre TEXT,
    p_email TEXT,
    p_password TEXT,
    p_hwid TEXT
)
RETURNS JSON AS $$
DECLARE
    nuevo_usuario_id UUID;
    licencia_disponible RECORD;
    resultado JSON;
BEGIN
    -- Verificar que el email no exista
    IF EXISTS (SELECT 1 FROM usuarios WHERE email = p_email) THEN
        resultado := json_build_object(
            'success', false,
            'error', 'EMAIL_EXISTE',
            'message', 'El email ya está registrado'
        );
        RETURN resultado;
    END IF;
    
    -- Buscar una licencia disponible (usuario_id IS NULL y activa = true)
    SELECT * INTO licencia_disponible 
    FROM licencias 
    WHERE usuario_id IS NULL 
    AND activa = true 
    LIMIT 1
    FOR UPDATE SKIP LOCKED; -- Evitar race conditions
    
    IF NOT FOUND THEN
        resultado := json_build_object(
            'success', false,
            'error', 'SIN_LICENCIAS_DISPONIBLES',
            'message', 'No hay licencias disponibles en este momento'
        );
        RETURN resultado;
    END IF;
    
    -- Crear usuario con password hash
    INSERT INTO usuarios (
        nombre,
        email,
        password_hash
    ) VALUES (
        p_nombre,
        p_email,
        crypt(p_password, gen_salt('bf'))
    ) RETURNING id INTO nuevo_usuario_id;
    
    -- Asignar licencia al usuario
    UPDATE licencias 
    SET 
        usuario_id = nuevo_usuario_id,
        hwid = p_hwid,
        fecha_activacion = NOW(),
        fecha_expiracion = NOW() + INTERVAL '1 year'
    WHERE id = licencia_disponible.id;
    
    resultado := json_build_object(
        'success', true,
        'message', 'USUARIO_CREADO_CON_LICENCIA',
        'usuario_id', nuevo_usuario_id,
        'licencia_id', licencia_disponible.id,
        'license_key', licencia_disponible.license_key,
        'fecha_expiracion', NOW() + INTERVAL '1 year'
    );
    RETURN resultado;
    
EXCEPTION
    WHEN unique_violation THEN
        resultado := json_build_object(
            'success', false,
            'error', 'EMAIL_EXISTE',
            'message', 'El email ya está registrado'
        );
        RETURN resultado;
END;
$$ LANGUAGE plpgsql;

-- Función para validar login con HWID
CREATE OR REPLACE FUNCTION validar_login_con_hwid(
    p_email TEXT,
    p_password TEXT,
    p_hwid TEXT
)
RETURNS JSON AS $$
DECLARE
    usuario_licencia RECORD;
    resultado JSON;
BEGIN
    -- Buscar usuario con su licencia asignada
    SELECT 
        u.id,
        u.nombre,
        u.email,
        u.activo as usuario_activo,
        l.id as licencia_id,
        l.license_key,
        l.hwid as licencia_hwid,
        l.activa as licencia_activa,
        l.fecha_expiracion,
        l.fecha_activacion
    INTO usuario_licencia
    FROM usuarios u
    LEFT JOIN licencias l ON u.id = l.usuario_id
    WHERE u.email = p_email
    AND u.activo = true;
    
    IF NOT FOUND THEN
        resultado := json_build_object(
            'success', false,
            'error', 'USUARIO_NO_ENCONTRADO',
            'message', 'Usuario no encontrado o inactivo'
        );
        RETURN resultado;
    END IF;
    
    -- Verificar que tenga licencia asignada
    IF usuario_licencia.licencia_id IS NULL THEN
        resultado := json_build_object(
            'success', false,
            'error', 'SIN_LICENCIA_ASIGNADA',
            'message', 'El usuario no tiene una licencia asignada'
        );
        RETURN resultado;
    END IF;
    
    -- Validar contraseña (bcrypt)
    IF NOT EXISTS (
        SELECT 1 
        FROM usuarios 
        WHERE id = usuario_licencia.id 
        AND password_hash = crypt(p_password, password_hash)
    ) THEN
        resultado := json_build_object(
            'success', false,
            'error', 'CREDENCIALES_INVALIDAS',
            'message', 'Email o contraseña incorrectos'
        );
        RETURN resultado;
    END IF;
    
    -- Validar licencia activa
    IF NOT usuario_licencia.licencia_activa THEN
        resultado := json_build_object(
            'success', false,
            'error', 'LICENCIA_INACTIVA',
            'message', 'La licencia asociada está inactiva'
        );
        RETURN resultado;
    END IF;
    
    -- Validar licencia no expirada
    IF usuario_licencia.fecha_expiracion < NOW() THEN
        resultado := json_build_object(
            'success', false,
            'error', 'LICENCIA_EXPIRADA',
            'message', 'La licencia ha expirado',
            'fecha_expiracion', usuario_licencia.fecha_expiracion
        );
        RETURN resultado;
    END IF;
    
    -- Validar HWID
    IF usuario_licencia.licencia_hwid != p_hwid THEN
        resultado := json_build_object(
            'success', false,
            'error', 'DISPOSITIVO_NO_AUTORIZADO',
            'message', 'El dispositivo no está autorizado para esta licencia'
        );
        RETURN resultado;
    END IF;
    
    -- Todo válido
    resultado := json_build_object(
        'success', true,
        'message', 'LOGIN_EXITOSO',
        'usuario', json_build_object(
            'id', usuario_licencia.id,
            'nombre', usuario_licencia.nombre,
            'email', usuario_licencia.email,
            'licencia_id', usuario_licencia.licencia_id,
            'license_key', usuario_licencia.license_key,
            'fecha_expiracion', usuario_licencia.fecha_expiracion,
            'fecha_activacion', usuario_licencia.fecha_activacion
        )
    );
    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar licencias disponibles
CREATE OR REPLACE FUNCTION verificar_licencias_disponibles()
RETURNS JSON AS $$
DECLARE
    disponibles INTEGER;
    total INTEGER;
    resultado JSON;
BEGIN
    -- Contar licencias disponibles
    SELECT COUNT(*) INTO disponibles
    FROM licencias 
    WHERE usuario_id IS NULL 
    AND activa = true;
    
    -- Contar total de licencias
    SELECT COUNT(*) INTO total
    FROM licencias 
    WHERE activa = true;
    
    resultado := json_build_object(
        'success', true,
        'disponibles', disponibles,
        'total', total,
        'asignadas', total - disponibles
    );
    
    RETURN resultado;
END;
$$ LANGUAGE plpgsql;
