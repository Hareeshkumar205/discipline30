-- Discipline 30 shared challenge schema for Supabase.
-- Run this entire file in Supabase SQL Editor. Use the anon/publishable key in config.js only.
-- Enable Anonymous Sign-Ins in Supabase Authentication settings before using the app.

create extension if not exists pgcrypto;

create table if not exists public.d30_challenges (
  id uuid primary key default gen_random_uuid(),
  join_code text not null unique,
  created_by uuid not null,
  created_at timestamptz not null default now()
);

create table if not exists public.d30_members (
  challenge_id uuid not null references public.d30_challenges(id) on delete cascade,
  user_id uuid not null,
  display_name text not null default 'Friend',
  joined_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);

create table if not exists public.d30_daily_logs (
  challenge_id uuid not null,
  user_id uuid not null,
  log_date date not null,
  gym_done boolean not null default false,
  gita_done boolean not null default false,
  reflection text not null default '',
  gita_reflection text not null default '',
  updated_at timestamptz not null default now(),
  primary key (challenge_id, user_id, log_date),
  foreign key (challenge_id, user_id) references public.d30_members(challenge_id, user_id) on delete cascade
);

alter table public.d30_challenges enable row level security;
alter table public.d30_members enable row level security;
alter table public.d30_daily_logs enable row level security;

-- No direct table access from browser clients; all access goes through the specific checked RPC functions below.
revoke all on public.d30_challenges from anon, authenticated;
revoke all on public.d30_members from anon, authenticated;
revoke all on public.d30_daily_logs from anon, authenticated;

create or replace function public.d30_create_challenge(p_display_name text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_challenge_id uuid;
  v_code text;
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'Sign in is required'; end if;
  v_code := upper(substr(encode(gen_random_bytes(8), 'hex'), 1, 8));
  insert into d30_challenges(join_code, created_by) values(v_code, v_uid) returning id into v_challenge_id;
  insert into d30_members(challenge_id, user_id, display_name) values(v_challenge_id, v_uid, left(coalesce(nullif(trim(p_display_name),''),'Friend'),40));
  return json_build_object('challenge_id', v_challenge_id, 'join_code', v_code);
end; $$;

create or replace function public.d30_join_challenge(p_join_code text, p_display_name text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_challenge_id uuid;
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'Sign in is required'; end if;
  select id into v_challenge_id from d30_challenges where join_code = upper(trim(p_join_code));
  if v_challenge_id is null then raise exception 'Room code not found'; end if;
  insert into d30_members(challenge_id, user_id, display_name)
  values(v_challenge_id, v_uid, left(coalesce(nullif(trim(p_display_name),''),'Friend'),40))
  on conflict (challenge_id,user_id) do update set display_name=excluded.display_name;
  return json_build_object('challenge_id',v_challenge_id);
end; $$;

create or replace function public.d30_save_daily_log(
  p_challenge_id uuid, p_log_date date, p_gym_done boolean, p_gita_done boolean,
  p_reflection text default '', p_gita_reflection text default ''
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null or not exists(select 1 from d30_members where challenge_id=p_challenge_id and user_id=v_uid) then
    raise exception 'You are not a member of this challenge';
  end if;
  insert into d30_daily_logs(challenge_id,user_id,log_date,gym_done,gita_done,reflection,gita_reflection,updated_at)
  values(p_challenge_id,v_uid,p_log_date,coalesce(p_gym_done,false),coalesce(p_gita_done,false),left(coalesce(p_reflection,''),400),left(coalesce(p_gita_reflection,''),500),now())
  on conflict(challenge_id,user_id,log_date) do update set
    gym_done=excluded.gym_done,gita_done=excluded.gita_done,reflection=excluded.reflection,
    gita_reflection=excluded.gita_reflection,updated_at=now();
  return json_build_object('saved',true);
end; $$;

create or replace function public.d30_get_challenge_progress(p_challenge_id uuid, p_log_date date)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare v_uid uuid := auth.uid(); v_result json;
begin
  if v_uid is null or not exists(select 1 from d30_members where challenge_id=p_challenge_id and user_id=v_uid) then
    raise exception 'You are not a member of this challenge';
  end if;
  select coalesce(json_agg(json_build_object(
    'display_name',m.display_name,
    'today',json_build_object('gym',coalesce(l.gym_done,false),'gita',coalesce(l.gita_done,false))
  ) order by m.joined_at),'[]'::json)
  into v_result
  from d30_members m left join d30_daily_logs l
    on l.challenge_id=m.challenge_id and l.user_id=m.user_id and l.log_date=p_log_date
  where m.challenge_id=p_challenge_id;
  return v_result;
end; $$;

revoke all on function public.d30_create_challenge(text) from public;
revoke all on function public.d30_join_challenge(text,text) from public;
revoke all on function public.d30_save_daily_log(uuid,date,boolean,boolean,text,text) from public;
revoke all on function public.d30_get_challenge_progress(uuid,date) from public;
grant execute on function public.d30_create_challenge(text) to anon, authenticated;
grant execute on function public.d30_join_challenge(text,text) to anon, authenticated;
grant execute on function public.d30_save_daily_log(uuid,date,boolean,boolean,text,text) to anon, authenticated;
grant execute on function public.d30_get_challenge_progress(uuid,date) to anon, authenticated;
