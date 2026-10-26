-- ==============================================================================
-- SISTEMA DE GESTIÓN DE MOTOS DE AGUA: "DIVINA ACUÁTICA"
-- Base de datos: PostgreSQL (Optimizado para Supabase)
-- ==============================================================================

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. TIPOS PERSONALIZADOS (ENUMS)
DO $$ BEGIN
    CREATE TYPE estado_moto_enum AS ENUM (
        'disponible',
        'en_agua',
        'mantenimiento',
        'fuera_de_servicio'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE estado_alquiler_enum AS ENUM (
        'activo',
        'finalizado',
        'cancelado'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 3. FUNCIÓN DE UTILIDAD: ACTUALIZACIÓN AUTOMÁTICA DE updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- TABLA: motos
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.motos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_unidad VARCHAR(50) NOT NULL UNIQUE, -- Ej: 'Yamaha 1', 'Yamaha 2'
    marca VARCHAR(50) NOT NULL DEFAULT 'Yamaha',
    modelo VARCHAR(50),
    horometro_actual NUMERIC(8, 2) NOT NULL DEFAULT 0.0 CHECK (horometro_actual >= 0),
    estado estado_moto_enum NOT NULL DEFAULT 'disponible',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_motos_updated_at
BEFORE UPDATE ON public.motos
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- TABLA: clientes
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_completo VARCHAR(150) NOT NULL,
    documento_identidad VARCHAR(50) NOT NULL UNIQUE, -- Cédula / Pasaporte
    telefono VARCHAR(30) NOT NULL,
    nacionalidad VARCHAR(60) DEFAULT 'Venezolana', -- o país/origen del turista
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_clientes_updated_at
BEFORE UPDATE ON public.clientes
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- TABLA: politicas_waivers (Términos legales y deslinde de responsabilidad)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.politicas_waivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titulo VARCHAR(200) NOT NULL,
    contenido_texto TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_politicas_waivers_updated_at
BEFORE UPDATE ON public.politicas_waivers
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- TABLA: alquileres
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.alquileres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    moto_id UUID NOT NULL REFERENCES public.motos(id) ON DELETE RESTRICT,
    cliente_id UUID NOT NULL REFERENCES public.clientes(id) ON DELETE RESTRICT,
    duracion_minutos INTEGER NOT NULL CHECK (duracion_minutos > 0),
    hora_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    hora_fin_estimada TIMESTAMPTZ NOT NULL,
    hora_fin_real TIMESTAMPTZ,
    horometro_inicio NUMERIC(8, 2) NOT NULL CHECK (horometro_inicio >= 0),
    horometro_fin NUMERIC(8, 2) CHECK (horometro_fin IS NULL OR horometro_fin >= horometro_inicio),
    estado estado_alquiler_enum NOT NULL DEFAULT 'activo',
    registrado_por VARCHAR(100) NOT NULL, -- Nombre o email del operador / asesor
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_alquileres_updated_at
BEFORE UPDATE ON public.alquileres
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- TABLA: firmas_clientes (Evidencia digital del deslinde / waiver firmado)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.firmas_clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alquiler_id UUID NOT NULL REFERENCES public.alquileres(id) ON DELETE CASCADE,
    cliente_id UUID NOT NULL REFERENCES public.clientes(id) ON DELETE RESTRICT,
    politica_id UUID NOT NULL REFERENCES public.politicas_waivers(id) ON DELETE RESTRICT,
    firma_url TEXT NOT NULL, -- URL pública o firmada en Supabase Storage
    fecha_firma TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_dispositivo VARCHAR(50), -- IP o User-Agent del dispositivo donde firmó
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- TABLA: mantenimientos
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.mantenimientos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    moto_id UUID NOT NULL REFERENCES public.motos(id) ON DELETE RESTRICT,
    tipo_servicio VARCHAR(80) NOT NULL, -- Ej: 'cambio_aceite', 'bujias', 'turbina', 'lavado_endulzado'
    horometro_servicio NUMERIC(8, 2) NOT NULL CHECK (horometro_servicio >= 0),
    descripcion TEXT,
    fecha_realizado TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    costo NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (costo >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 4. ÍNDICES DE RENDIMIENTO (Performance Indexes)
-- ==============================================================================
-- Búsqueda de motos por estado y nombre
CREATE INDEX IF NOT EXISTS idx_motos_estado ON public.motos(estado);
CREATE INDEX IF NOT EXISTS idx_motos_nombre ON public.motos(nombre_unidad);

-- Búsqueda rápida de clientes por documento de identidad y teléfono
CREATE INDEX IF NOT EXISTS idx_clientes_documento ON public.clientes(documento_identidad);
CREATE INDEX IF NOT EXISTS idx_clientes_telefono ON public.clientes(telefono);

-- Consultas operativas de alquileres (motos activas, historial de clientes, fechas)
CREATE INDEX IF NOT EXISTS idx_alquileres_moto_id ON public.alquileres(moto_id);
CREATE INDEX IF NOT EXISTS idx_alquileres_cliente_id ON public.alquileres(cliente_id);
CREATE INDEX IF NOT EXISTS idx_alquileres_estado ON public.alquileres(estado);
CREATE INDEX IF NOT EXISTS idx_alquileres_hora_inicio ON public.alquileres(hora_inicio DESC);

-- Firmas asociadas a alquiler y cliente
CREATE INDEX IF NOT EXISTS idx_firmas_alquiler_id ON public.firmas_clientes(alquiler_id);
CREATE INDEX IF NOT EXISTS idx_firmas_cliente_id ON public.firmas_clientes(cliente_id);

-- Historial de mantenimientos por moto y fecha
CREATE INDEX IF NOT EXISTS idx_mantenimientos_moto_id ON public.mantenimientos(moto_id);
CREATE INDEX IF NOT EXISTS idx_mantenimientos_fecha ON public.mantenimientos(fecha_realizado DESC);

-- Políticas activas
CREATE INDEX IF NOT EXISTS idx_politicas_activo ON public.politicas_waivers(activo);

-- ==============================================================================
-- 5. TRIGGER DE INTEGRIDAD: SINCRONIZACIÓN DE ESTADO Y HORÓMETRO DE MOTO
-- ==============================================================================
-- Al registrar un alquiler nuevo activo -> la moto pasa a 'en_agua'
-- Al finalizar un alquiler -> la moto pasa a 'disponible' y se actualiza su horómetro actual
CREATE OR REPLACE FUNCTION trg_sync_moto_status_func()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF NEW.estado = 'activo' THEN
            UPDATE public.motos
            SET estado = 'en_agua'
            WHERE id = NEW.moto_id;
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF NEW.estado = 'finalizado' AND OLD.estado = 'activo' THEN
            UPDATE public.motos
            SET estado = 'disponible',
                horometro_actual = COALESCE(NEW.horometro_fin, horometro_actual)
            WHERE id = NEW.moto_id;
        ELSIF NEW.estado = 'cancelado' AND OLD.estado = 'activo' THEN
            UPDATE public.motos
            SET estado = 'disponible'
            WHERE id = NEW.moto_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_moto_status
AFTER INSERT OR UPDATE OF estado, horometro_fin ON public.alquileres
FOR EACH ROW EXECUTE FUNCTION trg_sync_moto_status_func();

-- ==============================================================================
-- 6. SEGURIDAD: ROW LEVEL SECURITY (RLS)
-- ==============================================================================
-- Habilitar RLS en todas las tablas
ALTER TABLE public.motos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.politicas_waivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alquileres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firmas_clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mantenimientos ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- Políticas para usuarios autenticados (Operadores, Recepcionistas, Administradores)
-- En Supabase, cualquier usuario con sesión iniciada tiene el rol `authenticated`.
-- ------------------------------------------------------------------------------
CREATE POLICY "Acceso total para operadores autenticados en motos"
    ON public.motos FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Acceso total para operadores autenticados en clientes"
    ON public.clientes FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Acceso total para operadores autenticados en alquileres"
    ON public.alquileres FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Acceso total para operadores autenticados en mantenimientos"
    ON public.mantenimientos FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Lectura y gestión de políticas para autenticados"
    ON public.politicas_waivers FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Acceso total a firmas para autenticados"
    ON public.firmas_clientes FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- Políticas públicas (Anon)
-- Útil para que clientes o quioscos/tablets puedan leer la política activa
-- y enviar la firma digital sin requerir login en Supabase Auth.
-- ------------------------------------------------------------------------------
CREATE POLICY "Lectura publica de politicas activas"
    ON public.politicas_waivers FOR SELECT
    TO anon
    USING (activo = true);

CREATE POLICY "Permitir registro anonimo de firmas desde tablet/web"
    ON public.firmas_clientes FOR INSERT
    TO anon
    WITH CHECK (true);

-- ==============================================================================
-- 7. DATOS INICIALES (SEMILLA / SEED DATA)
-- ==============================================================================
INSERT INTO public.politicas_waivers (titulo, contenido_texto, version, activo)
VALUES (
    'Deslinde de Responsabilidad y Normas de Navegación - Playa Parguito',
    'Yo declaro voluntariamente que conozco y asumo todos los riesgos inherentes a la conducción y navegación de motos acuáticas en las instalaciones y aguas designadas de Divina Acuática. Me comprometo a respetar los límites de velocidad cerca de la orilla, portar chaleco salvavidas en todo momento y no operar bajo influencia de alcohol o sustancias psicotrópicas.',
    1,
    true
)
ON CONFLICT DO NOTHING;


-- ==============================================================================
-- FASE 1 & 2: CATÁLOGO DE SERVICIOS, TASAS BCV Y CAJA BIMONEDA (USD / BS)
-- ==============================================================================

-- 8. TIPOS PARA CAJA Y PAGOS
DO $$ BEGIN
    CREATE TYPE metodo_pago_enum AS ENUM (
        'usd_efectivo',
        'pago_movil_bs',
        'zelle',
        'punto_venta_bs',
        'efectivo_bs',
        'mixto'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE estado_pago_enum AS ENUM (
        'completado',
        'pendiente',
        'anulado'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 9. TABLA: tasas_cambio_bcv (Registro histórico y diario de la tasa oficial)
CREATE TABLE IF NOT EXISTS public.tasas_cambio_bcv (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    tasa_oficial NUMERIC(12, 4) NOT NULL CHECK (tasa_oficial > 0),
    fuente VARCHAR(50) NOT NULL DEFAULT 'DolarApi BCV', -- 'DolarApi BCV', 'Manual Operador'
    registrado_por VARCHAR(100) DEFAULT 'Sistema',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasas_bcv_fecha ON public.tasas_cambio_bcv(fecha DESC);

-- 10. TABLA: catalogo_servicios (Servicios y tarifas configurables en USD)
CREATE TABLE IF NOT EXISTS public.catalogo_servicios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(120) NOT NULL,
    categoria VARCHAR(50) NOT NULL DEFAULT 'jetski', -- 'jetski', 'kayak', 'inflables', 'accesorios'
    duracion_minutos INTEGER NOT NULL CHECK (duracion_minutos >= 0),
    precio_base_usd NUMERIC(10, 2) NOT NULL CHECK (precio_base_usd >= 0),
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_catalogo_servicios_updated_at
BEFORE UPDATE ON public.catalogo_servicios
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 11. TABLA: pagos_alquileres (Registro bimoneda y cobros en playa)
CREATE TABLE IF NOT EXISTS public.pagos_alquileres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alquiler_id UUID REFERENCES public.alquileres(id) ON DELETE SET NULL,
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL,
    monto_total_usd NUMERIC(10, 2) NOT NULL CHECK (monto_total_usd >= 0),
    tasa_bcv_aplicada NUMERIC(12, 4) NOT NULL CHECK (tasa_bcv_aplicada > 0),
    monto_total_bs NUMERIC(14, 2) NOT NULL CHECK (monto_total_bs >= 0),
    metodo_pago metodo_pago_enum NOT NULL DEFAULT 'usd_efectivo',
    monto_pagado_usd NUMERIC(10, 2) DEFAULT 0.00,
    monto_pagado_bs NUMERIC(14, 2) DEFAULT 0.00,
    referencia_bancaria VARCHAR(100),
    banco_destino VARCHAR(80),
    estado_pago estado_pago_enum NOT NULL DEFAULT 'completado',
    registrado_por VARCHAR(100) NOT NULL,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pagos_alquiler_id ON public.pagos_alquileres(alquiler_id);
CREATE INDEX IF NOT EXISTS idx_pagos_cliente_id ON public.pagos_alquileres(cliente_id);
CREATE INDEX IF NOT EXISTS idx_pagos_fecha ON public.pagos_alquileres(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pagos_metodo ON public.pagos_alquileres(metodo_pago);

-- Habilitar RLS en nuevas tablas
ALTER TABLE public.tasas_cambio_bcv ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.catalogo_servicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pagos_alquileres ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acceso total para operadores en tasas_cambio_bcv"
    ON public.tasas_cambio_bcv FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Lectura publica de tasa del dia"
    ON public.tasas_cambio_bcv FOR SELECT TO anon USING (true);

CREATE POLICY "Acceso total para operadores en catalogo_servicios"
    ON public.catalogo_servicios FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Lectura publica de catalogo de servicios activos"
    ON public.catalogo_servicios FOR SELECT TO anon USING (activo = true);

CREATE POLICY "Acceso total para operadores en pagos_alquileres"
    ON public.pagos_alquileres FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Semilla inicial de Catálogo de Servicios para Divina Acuática
INSERT INTO public.catalogo_servicios (nombre, categoria, duracion_minutos, precio_base_usd, descripcion)
VALUES 
    ('Moto de Agua Yamaha (15 Minutos - Mínimo)', 'jetski', 15, 40.00, 'Vuelta rápida de playa en circuito delimitado'),
    ('Moto de Agua Yamaha (20 Minutos)', 'jetski', 20, 50.00, 'Paseo estándar costero'),
    ('Moto de Agua Yamaha (30 Minutos - Bahía)', 'jetski', 30, 70.00, 'Tour completo frente a Playa Parguito y bahía'),
    ('Moto de Agua Yamaha (60 Minutos - 1 Hora)', 'jetski', 60, 130.00, 'Hora completa de navegación con acompañante libre'),
    ('Kayak Doble (1 Hora)', 'kayak', 60, 20.00, 'Alquiler con remos y chalecos de travesía'),
    ('Banana Boat Acuática (Por persona)', 'inflables', 15, 10.00, 'Paseo arrastrado en lancha o moto con chaleco')
ON CONFLICT DO NOTHING;
