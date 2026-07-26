-- ====================================================================
-- FARMAJÁ ANGOLA 🇦🇴 • SUPABASE DATABASE SCHEMA & RLS POLICIES
-- ====================================================================

-- 1. EXTENSIONS & SCHEMAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS / PROFILES TABLE
-- Linked directly to Supabase Auth (auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'pharmacy', 'admin')),
  province TEXT DEFAULT 'Luanda',
  municipality TEXT DEFAULT 'Talatona',
  insurance_provider TEXT DEFAULT 'ENSA Seguros',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. PHARMACIES TABLE
CREATE TABLE IF NOT EXISTS public.pharmacies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  province TEXT NOT NULL DEFAULT 'Luanda',
  municipality TEXT NOT NULL DEFAULT 'Talatona',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone TEXT,
  email TEXT,
  verified BOOLEAN DEFAULT false NOT NULL,
  is_open_24h BOOLEAN DEFAULT false NOT NULL,
  opening_hours TEXT DEFAULT '08:00 - 22:00',
  logo_url TEXT,
  -- SUBSCRIPTION FIELDS
  subscription_status TEXT NOT NULL DEFAULT 'trial' CHECK (subscription_status IN ('trial', 'active', 'expired', 'blocked')),
  trial_ends_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + interval '90 days') NOT NULL,
  payment_due_date TIMESTAMP WITH TIME ZONE DEFAULT (now() + interval '90 days') NOT NULL,
  monthly_fee NUMERIC(12, 2) NOT NULL DEFAULT 15000.00,
  last_payment_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3B. PHARMACY PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS public.pharmacy_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  pharmacy_name TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL DEFAULT 15000.00,
  payment_method TEXT NOT NULL DEFAULT 'Transferência IBAN', -- IBAN, Multicaixa Express, BAI Directo
  reference_number TEXT,
  proof_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  period_months INT DEFAULT 1,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  approved_at TIMESTAMP WITH TIME ZONE
);

-- 4. MEDICINES TABLE
CREATE TABLE IF NOT EXISTS public.medicines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  generic_name TEXT,
  category TEXT NOT NULL DEFAULT 'Geral',
  description TEXT,
  dosage TEXT DEFAULT 'Comprimidos',
  price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  stock INT NOT NULL DEFAULT 0,
  prescription_required BOOLEAN DEFAULT false NOT NULL,
  image_url TEXT,
  is_generic BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. RESERVATIONS TABLE
CREATE TABLE IF NOT EXISTS public.reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  medicine_id UUID NOT NULL REFERENCES public.medicines(id) ON DELETE CASCADE,
  pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
  reservation_code TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'expired')),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() + interval '24 hours'),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. PRESCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reservation_id UUID REFERENCES public.reservations(id) ON DELETE SET NULL,
  image_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ====================================================================
-- INDEXES FOR MAXIMUM QUERY PERFORMANCE IN ANGOLA
-- ====================================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_pharmacies_province ON public.pharmacies(province, municipality);
CREATE INDEX IF NOT EXISTS idx_pharmacies_verified ON public.pharmacies(verified);
CREATE INDEX IF NOT EXISTS idx_medicines_pharmacy ON public.medicines(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_medicines_name ON public.medicines(name, generic_name);
CREATE INDEX IF NOT EXISTS idx_medicines_category ON public.medicines(category);
CREATE INDEX IF NOT EXISTS idx_reservations_user ON public.reservations(user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_pharmacy ON public.reservations(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_reservations_code ON public.reservations(reservation_code);
CREATE INDEX IF NOT EXISTS idx_prescriptions_user ON public.prescriptions(user_id);

-- ====================================================================
-- AUTOMATIC NEW USER HANDLER (TRIGGER FROM SUPABASE AUTH)
-- ====================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, full_name, email, phone, province, municipality, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'Utilizador FarmaJá'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    COALESCE(new.raw_user_meta_data->>'province', 'Luanda'),
    COALESCE(new.raw_user_meta_data->>'municipality', 'Talatona'),
    COALESCE(new.raw_user_meta_data->>'role', 'customer')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger execution on Auth Signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ====================================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- 1. USERS POLICIES
-- --------------------------------------------------------------------
CREATE POLICY "Users can view their own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- --------------------------------------------------------------------
-- 2. PHARMACIES POLICIES
-- --------------------------------------------------------------------
CREATE POLICY "Anyone can view verified pharmacies"
  ON public.pharmacies FOR SELECT
  USING (true);

CREATE POLICY "Pharmacies and Admins can insert/update pharmacy info"
  ON public.pharmacies FOR ALL
  USING (auth.uid() IN (SELECT id FROM public.users WHERE role IN ('pharmacy', 'admin')));

-- --------------------------------------------------------------------
-- 3. MEDICINES POLICIES
-- --------------------------------------------------------------------
CREATE POLICY "Anyone can view medicines stock"
  ON public.medicines FOR SELECT
  USING (true);

CREATE POLICY "Pharmacy staff can manage their medicines"
  ON public.medicines FOR ALL
  USING (auth.uid() IN (SELECT id FROM public.users WHERE role IN ('pharmacy', 'admin')));

-- --------------------------------------------------------------------
-- 4. RESERVATIONS POLICIES
-- --------------------------------------------------------------------
CREATE POLICY "Users can view their own reservations"
  ON public.reservations FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.users WHERE role IN ('pharmacy', 'admin')));

CREATE POLICY "Users can create reservations"
  ON public.reservations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users and Pharmacies can update reservation status"
  ON public.reservations FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.users WHERE role IN ('pharmacy', 'admin')));

-- --------------------------------------------------------------------
-- 5. PRESCRIPTIONS POLICIES
-- --------------------------------------------------------------------
CREATE POLICY "Users can view their own prescriptions"
  ON public.prescriptions FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.users WHERE role IN ('pharmacy', 'admin')));

CREATE POLICY "Users can upload prescriptions"
  ON public.prescriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ====================================================================
-- SUPABASE STORAGE BUCKETS & POLICIES
-- ====================================================================

-- Create Storage Buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('prescriptions', 'prescriptions', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('medicine-images', 'medicine-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for Prescriptions Bucket
CREATE POLICY "Authenticated users can upload prescription images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'prescriptions' AND auth.role() = 'authenticated');

CREATE POLICY "Users can read their prescription images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'prescriptions' AND auth.role() = 'authenticated');

-- Storage Policies for Medicine Images Bucket
CREATE POLICY "Public read for medicine images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'medicine-images');

CREATE POLICY "Pharmacy staff upload medicine images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'medicine-images' AND auth.role() = 'authenticated');

-- ====================================================================
-- SEED DATA FOR ANGOLA PHARMACIES & MEDICINES
-- ====================================================================

INSERT INTO public.pharmacies (id, name, address, province, municipality, latitude, longitude, phone, email, verified, is_open_24h, opening_hours)
VALUES
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Farmácia Mecofarma Talatona', 'Via AL15, Próximo ao Shopping Avennida', 'Luanda', 'Talatona', -8.9167, 13.1833, '+244 923 100 200', 'talatona@mecofarma.co.ao', true, true, '24 Horas / 7 Dias'),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Farmácia Sagrada Esperança', 'Avenida Lenine, Edifício Clínica', 'Luanda', 'Maianga', -8.8233, 13.2344, '+244 912 300 400', 'farmacia@sagradaesperanca.ao', true, false, '07:30 - 22:00'),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'Farmácia Central Benguela', 'Avenida 10 de Fevereiro', 'Benguela', 'Benguela Centro', -12.5783, 13.4072, '+244 931 222 333', 'benguela@farmaja.ao', true, true, '24 Horas / 7 Dias')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.medicines (id, pharmacy_id, name, generic_name, category, description, dosage, price, stock, prescription_required, is_generic)
VALUES
  ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b11', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Coartem 80/480mg', 'Artemeter + Lumefantrina', 'Antimaláricos', 'Tratamento de primeira escolha para a malária por Plasmodium falciparum em Angola.', 'Caixa com 6 Comprimidos', 4500.00, 30, true, false),
  ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b22', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Paracetamol 500mg Bial', 'Paracetamol', 'Analgésicos', 'Alívio rápido de dores ligeiras a moderadas e estado febril.', 'Caixa de 20 Comprimidos', 1200.00, 100, false, false),
  ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b33', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Amoxicilina 500mg Genérico', 'Amoxicilina Tri-hidratada', 'Antibióticos', 'Antibiótico bactericida de amplo espectro para infecções bacterianas.', 'Caixa de 16 Cápsulas', 2800.00, 20, true, true)
ON CONFLICT (id) DO NOTHING;
