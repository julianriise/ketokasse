-- Authenticated users can delete their own auth user (testing + account reset).
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  hid uuid;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  select household_id into hid
  from public.household_members
  where user_id = uid;

  delete from public.household_members where user_id = uid;

  if hid is not null and not exists (
    select 1 from public.household_members where household_id = hid
  ) then
    delete from public.households where id = hid;
  end if;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
revoke all on function public.delete_own_account() from anon;
grant execute on function public.delete_own_account() to authenticated;
