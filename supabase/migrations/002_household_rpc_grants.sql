-- Lock SECURITY DEFINER RPCs: no anon execute; authenticated only for invite/household.
revoke all on function public.handle_new_user() from public;
revoke all on function public.handle_new_user() from anon, authenticated;

revoke all on function public.is_household_member(uuid) from public;
revoke all on function public.is_household_member(uuid) from anon, authenticated;

revoke all on function public.ensure_own_household() from public;
revoke all on function public.ensure_own_household() from anon;
grant execute on function public.ensure_own_household() to authenticated;

revoke all on function public.create_invite() from public;
revoke all on function public.create_invite() from anon;
grant execute on function public.create_invite() to authenticated;

revoke all on function public.redeem_invite(text) from public;
revoke all on function public.redeem_invite(text) from anon;
grant execute on function public.redeem_invite(text) to authenticated;
