-- Supabase SQL Schema for Dementia Care App
-- This script sets up the tables, triggers, and Row Level Security (RLS) policies.

-- 1. Create Profiles Table (extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    role TEXT NOT NULL CHECK (role IN ('patient', 'caregiver')),
    name TEXT,
    age INT,
    condition TEXT,
    blood_group TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Medications Table
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
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create Emergency Alerts Table
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

-- 6. Setup RLS Policies

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

-- 7. Automated Profile Creation Trigger
-- When a user registers through Supabase Auth, automatically insert a blank profile.
-- You can specify the role in the user metadata during signup (e.g. metadata: { role: 'patient' })
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, role, name)
    VALUES (
        new.id,
        coalesce(new.raw_user_meta_data->>'role', 'patient'),
        coalesce(new.raw_user_meta_data->>'name', 'New User')
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
