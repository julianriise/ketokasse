-- Enable Postgres Changes for household sync.
-- Apply in the ketokasse project (Oskar / dashboard SQL editor or supabase db push).

alter publication supabase_realtime add table public.week_plans;
alter publication supabase_realtime add table public.households;
