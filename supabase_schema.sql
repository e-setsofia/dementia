-- Supabase SQL Schema for Dementia Care App
-- This script sets up the tables, triggers, and Row Level Security (RLS) policies.

-- 1. Create Profiles Table (extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    role TEXT NOT NULL CHECK (role IN ('patient', 'caregiver')),
    name TEXT,
    age INT,
    condition TEXT,           -- legacy: keep for compatibility
    blood_group TEXT,
    medical_conditions TEXT,  -- free-text, comma-separated conditions
    allergies TEXT,           -- free-text, comma-separated allergies
    pairing_code TEXT UNIQUE, -- 6-character code for patient pairing
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Caregiver–Patient Link Table
-- Links each caregiver account to one or more patient accounts.
-- After creating both accounts, insert a row here to pair them.
CREATE TABLE IF NOT EXISTS public.caregiver_patients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    caregiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(caregiver_id, patient_id)
);

-- 3. Create Medications Table
CREATE TABLE IF NOT EXISTS public.medications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    drug TEXT NOT NULL,
    dose TEXT NOT NULL,
    time TEXT NOT NULL, -- e.g., 'Morning', '8:00 AM'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Daily Schedules Table
CREATE TABLE IF NOT EXISTS public.schedules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    task TEXT NOT NULL,
    time TEXT NOT NULL, -- e.g., '8:00 AM'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create Appointments Table
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    doctor_name TEXT,
    appointment_time TIMESTAMPTZ NOT NULL,
    attended BOOLEAN DEFAULT false,   -- updated after the appointment
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create Medication Logs Table (tracks taken / missed events)
CREATE TABLE IF NOT EXISTS public.medication_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    medication_id UUID REFERENCES public.medications(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('taken', 'missed')),
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create Emergency Alerts Table
CREATE TABLE IF NOT EXISTS public.emergency_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS) for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;

-- 7. Setup RLS Policies

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" 
ON public.profiles FOR SELECT 
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Caregivers can view patient profiles" ON public.profiles;
CREATE POLICY "Caregivers can view patient profiles" 
ON public.profiles FOR SELECT 
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'caregiver'
);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- Medications Policies
DROP POLICY IF EXISTS "Patients can view their own medications" ON public.medications;
CREATE POLICY "Patients can view their own medications" 
ON public.medications FOR SELECT 
USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Caregivers can manage medications" ON public.medications;
CREATE POLICY "Caregivers can manage medications" 
ON public.medications FOR ALL 
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'caregiver'
);

-- Schedules Policies
DROP POLICY IF EXISTS "Patients can view their own schedules" ON public.schedules;
CREATE POLICY "Patients can view their own schedules" 
ON public.schedules FOR SELECT 
USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Caregivers can manage schedules" ON public.schedules;
CREATE POLICY "Caregivers can manage schedules" 
ON public.schedules FOR ALL 
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'caregiver'
);

-- Appointments Policies
DROP POLICY IF EXISTS "Patients can view their own appointments" ON public.appointments;
CREATE POLICY "Patients can view their own appointments" 
ON public.appointments FOR SELECT 
USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Caregivers can manage appointments" ON public.appointments;
CREATE POLICY "Caregivers can manage appointments" 
ON public.appointments FOR ALL 
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'caregiver'
);

-- Emergency Alerts Policies
DROP POLICY IF EXISTS "Patients can create emergency alerts" ON public.emergency_alerts;
CREATE POLICY "Patients can create emergency alerts" 
ON public.emergency_alerts FOR INSERT 
WITH CHECK (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Caregivers can view and manage alerts" ON public.emergency_alerts;
CREATE POLICY "Caregivers can view and manage alerts" 
ON public.emergency_alerts FOR ALL 
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'caregiver'
);

-- Medication Logs Policies
DROP POLICY IF EXISTS "Patients can log their own medications" ON public.medication_logs;
CREATE POLICY "Patients can log their own medications"
ON public.medication_logs FOR INSERT
WITH CHECK (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can view their own medication logs" ON public.medication_logs;
CREATE POLICY "Patients can view their own medication logs"
ON public.medication_logs FOR SELECT
USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Caregivers can view and manage medication logs" ON public.medication_logs;
CREATE POLICY "Caregivers can view and manage medication logs"
ON public.medication_logs FOR ALL
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'caregiver'
);

-- 8. Automated Profile Creation Trigger
-- When a user registers through Supabase Auth, automatically insert a blank profile.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_pairing_code TEXT;
BEGIN
    -- Generate a 6-character alphanumeric code only for patients
    IF coalesce(new.raw_user_meta_data->>'role', 'patient') = 'patient' THEN
        new_pairing_code := upper(substring(md5(random()::text) from 1 for 6));
    ELSE
        new_pairing_code := NULL;
    END IF;

    INSERT INTO public.profiles (id, role, name, pairing_code)
    VALUES (
        new.id,
        coalesce(new.raw_user_meta_data->>'role', 'patient'),
        coalesce(new.raw_user_meta_data->>'name', 'New User'),
        new_pairing_code
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 9. RPC Function for Pairing Caregiver to Patient
CREATE OR REPLACE FUNCTION public.pair_caregiver(p_code TEXT)
RETURNS void AS $$
DECLARE
    target_patient_id UUID;
BEGIN
    -- Find the patient with the matching code
    SELECT id INTO target_patient_id
    FROM public.profiles
    WHERE pairing_code = p_code AND role = 'patient';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid pairing code';
    END IF;

    -- Insert the pairing (assuming auth.uid() is the caregiver)
    INSERT INTO public.caregiver_patients (caregiver_id, patient_id)
    VALUES (auth.uid(), target_patient_id)
    ON CONFLICT (caregiver_id, patient_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
