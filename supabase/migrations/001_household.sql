-- Ketokasse household sync (v1)
-- Apply with Supabase CLI: supabase db push
-- Or paste into Supabase SQL editor.

create extension if not exists "pgcrypto";

-- Auth users live in auth.users (Supabase). profiles are app-facing.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  display_name text,
  created_at timestamptz not null default now()
);

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Familie',
  points_total int not null default 0 check (points_total >= 0),
  created_at timestamptz not null default now()
);

create type public.household_role as enum ('owner', 'member');

create table public.household_members (
  household_id uuid not null references public.households (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.household_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (household_id, user_id)
);

create unique index household_members_one_home_per_user
  on public.household_members (user_id);

-- Invite QR encodes deep link with token (not household id).
create table public.household_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  token text not null unique default encode(gen_random_bytes(16), 'hex'),
  created_by uuid not null references public.profiles (id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '7 days'),
  redeemed_by uuid references public.profiles (id) on delete set null,
  redeemed_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > created_at)
);

create index household_invites_token_live
  on public.household_invites (token)
  where redeemed_at is null;

-- One active week plan per household (slots = 7 titles or null).
create table public.week_plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  week_start date not null,
  slots text[] not null check (cardinality(slots) = 7),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id) on delete set null,
  unique (household_id, week_start)
);

-- Cooking completion: who cooked which day (points land on household).
create table public.cook_events (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  cooked_by uuid not null references public.profiles (id) on delete cascade,
  dish_title text not null,
  day_index smallint not null check (day_index between 0 and 6),
  points_awarded int not null default 0 check (points_awarded >= 0),
  cooked_at timestamptz not null default now()
);

create index cook_events_household_day
  on public.cook_events (household_id, cooked_at desc);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- First login: ensure a household exists (owner).
create or replace function public.ensure_own_household()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  hid uuid;
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  select household_id into hid
  from public.household_members
  where user_id = uid;

  if hid is not null then
    return hid;
  end if;

  insert into public.households (name)
  values ('Familie')
  returning id into hid;

  insert into public.household_members (household_id, user_id, role)
  values (hid, uid, 'owner');

  return hid;
end;
$$;

create or replace function public.create_invite()
returns table (token text, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  hid uuid;
  inv public.household_invites;
begin
  hid := public.ensure_own_household();

  insert into public.household_invites (household_id, created_by)
  values (hid, auth.uid())
  returning * into inv;

  return query select inv.token, inv.expires_at;
end;
$$;

-- Redeemer leaves their solo household (if empty of others) and joins invite home.
create or replace function public.redeem_invite(invite_token text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  inv public.household_invites;
  uid uuid := auth.uid();
  old_hid uuid;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  select * into inv
  from public.household_invites
  where token = invite_token
    and redeemed_at is null
    and expires_at > now()
  for update;

  if not found then
    raise exception 'invite invalid or expired';
  end if;

  if exists (
    select 1 from public.household_members
    where household_id = inv.household_id and user_id = uid
  ) then
    return inv.household_id;
  end if;

  select household_id into old_hid
  from public.household_members
  where user_id = uid;

  delete from public.household_members where user_id = uid;

  -- Drop orphan solo household the redeemer just left
  if old_hid is not null and not exists (
    select 1 from public.household_members where household_id = old_hid
  ) then
    delete from public.households where id = old_hid;
  end if;

  insert into public.household_members (household_id, user_id, role)
  values (inv.household_id, uid, 'member');

  update public.household_invites
  set redeemed_by = uid, redeemed_at = now()
  where id = inv.id;

  return inv.household_id;
end;
$$;

-- RLS
alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.household_invites enable row level security;
alter table public.week_plans enable row level security;
alter table public.cook_events enable row level security;

create or replace function public.is_household_member(hid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.household_members
    where household_id = hid and user_id = auth.uid()
  );
$$;

create policy profiles_self on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy households_member_select on public.households
  for select using (public.is_household_member(id));

create policy households_member_update on public.households
  for update using (public.is_household_member(id));

create policy members_same_home on public.household_members
  for select using (public.is_household_member(household_id));

create policy invites_owner_rw on public.household_invites
  for all using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));

create policy week_plans_member on public.week_plans
  for all using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));

create policy cook_events_member on public.cook_events
  for all using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));
