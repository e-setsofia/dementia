import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client shortcut — getter ensures access is always after initialization
SupabaseClient get supabase => Supabase.instance.client;
