create table public.feedback (
 id bigint generated always as identity primary key,
 kind text not null check (kind in ('suggestion','complaint','note')),
 name text not null default '' check (char_length(name)<=80),
 contact text not null default '' check (char_length(contact)<=120),
 message text not null check (char_length(btrim(message)) between 5 and 2000),
 status text not null default 'new' check (status in ('new','reviewing','resolved')),
 created_at timestamptz not null default now()
);
alter table public.feedback enable row level security;
revoke all on public.feedback from anon,authenticated;
grant insert (kind,name,contact,message) on public.feedback to anon,authenticated;
grant select,update on public.feedback to authenticated;
grant usage on sequence public.feedback_id_seq to anon,authenticated;
create policy visitor_submit_feedback on public.feedback for insert to anon,authenticated with check (status='new');
create policy admin_read_feedback on public.feedback for select to authenticated using ((select private.is_site_admin()));
create policy admin_update_feedback on public.feedback for update to authenticated using ((select private.is_site_admin())) with check ((select private.is_site_admin()));
create index feedback_created_at_idx on public.feedback (created_at desc);
create function public.is_site_admin() returns boolean language sql stable security invoker set search_path='' as $$ select private.is_site_admin(); $$;
revoke all on function public.is_site_admin() from public,anon;
grant execute on function public.is_site_admin() to authenticated;
notify pgrst,'reload schema';