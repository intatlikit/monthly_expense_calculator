-- Run once in Supabase Dashboard → SQL Editor.
-- One row per sync key; data is the whole profiles array from the app.
-- RLS is on with no policies, so the anon key cannot read or list the table directly:
-- clients can only reach a row through the functions below by knowing its sync key.

create table if not exists public.expense_sync (
  sync_key   text primary key,
  data       jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.expense_sync enable row level security;

create or replace function public.get_expense_data(p_key text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select data from expense_sync where sync_key = p_key;
$$;

create or replace function public.save_expense_data(p_key text, p_data jsonb)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  ts timestamptz;
begin
  if p_key is null or length(p_key) < 8 then
    raise exception 'sync key must be at least 8 characters';
  end if;
  if jsonb_typeof(p_data) <> 'array' then
    raise exception 'data must be a JSON array';
  end if;
  insert into expense_sync (sync_key, data, updated_at)
  values (p_key, p_data, now())
  on conflict (sync_key) do update set data = excluded.data, updated_at = now()
  returning updated_at into ts;
  return ts;
end;
$$;

revoke all on function public.get_expense_data(text) from public;
revoke all on function public.save_expense_data(text, jsonb) from public;
grant execute on function public.get_expense_data(text) to anon, authenticated;
grant execute on function public.save_expense_data(text, jsonb) to anon, authenticated;
