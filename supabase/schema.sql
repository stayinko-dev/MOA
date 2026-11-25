-- MOA 2.0 initial schema. Review in a non-production Supabase project first.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text not null default '',
  avatar_url text,
  bio text not null default '',
  region text,
  language text not null default 'en' check (language in ('en','ko')),
  interests text[] not null default '{}',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (cardinality(interests) <= 10)
);
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null default '', language text not null default 'en' check(language in ('en','ko')),
  visibility text not null default 'public' check(visibility in ('public','followers')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (char_length(body) <= 500)
);
create table if not exists public.post_media (
  id uuid primary key default gen_random_uuid(), post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade, storage_path text not null,
  media_type text not null check(media_type in ('image','video')), position smallint not null default 0 check(position between 0 and 4),
  created_at timestamptz not null default now(), unique(post_id,position)
);
create table if not exists public.post_topics (
  post_id uuid not null references public.posts(id) on delete cascade, topic text not null,
  primary key(post_id,topic)
);
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(), post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade, parent_id uuid references public.comments(id) on delete cascade,
  body text not null check(char_length(body) between 1 and 2000), created_at timestamptz not null default now()
);
create table if not exists public.likes (
  post_id uuid not null references public.posts(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(), primary key(post_id,user_id)
);
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade, followed_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(), primary key(follower_id,followed_id), check(follower_id<>followed_id)
);

create table if not exists public.meetups (
  id uuid primary key default gen_random_uuid(), host_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check(char_length(name) between 2 and 100), description text not null default '', image_path text,
  topic text not null, format text not null default 'offline' check(format in ('online','offline','both')),
  city text, join_policy text not null default 'public' check(join_policy in ('public','approval')),
  status text not null default 'active' check(status in ('active','archived')), created_at timestamptz not null default now()
);
create table if not exists public.meetup_members (
  meetup_id uuid not null references public.meetups(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check(role in ('host','moderator','member')),
  status text not null default 'active' check(status in ('pending','active','rejected')),
  created_at timestamptz not null default now(), primary key(meetup_id,user_id)
);
create table if not exists public.meetup_posts (
  id uuid primary key default gen_random_uuid(), meetup_id uuid not null references public.meetups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade, body text not null check(char_length(body) between 1 and 5000),
  pinned_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.meetup_events (
  id uuid primary key default gen_random_uuid(), meetup_id uuid not null references public.meetups(id) on delete cascade,
  creator_id uuid not null references public.profiles(id) on delete cascade, title text not null,
  description text not null default '', starts_at timestamptz not null, timezone text not null,
  location text, online_info text, capacity integer check(capacity is null or capacity > 0), created_at timestamptz not null default now()
);
create table if not exists public.event_rsvps (
  event_id uuid not null references public.meetup_events(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'going' check(status in ('going','cancelled','waitlisted')), created_at timestamptz not null default now(),
  primary key(event_id,user_id)
);

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(), creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check(char_length(title) between 2 and 100), description text not null default '', image_path text,
  topic text not null, starts_on date not null, ends_on date not null, max_participants integer check(max_participants is null or max_participants > 0),
  daily_checkin boolean not null default true, paid boolean not null default false check(paid = false),
  created_at timestamptz not null default now(), check(ends_on >= starts_on)
);
create table if not exists public.challenge_members (
  challenge_id uuid not null references public.challenges(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(), primary key(challenge_id,user_id)
);
create table if not exists public.challenge_checkins (
  id uuid primary key default gen_random_uuid(), challenge_id uuid not null, user_id uuid not null,
  checkin_date date not null, note text not null default '', media_path text, created_at timestamptz not null default now(),
  unique(challenge_id,user_id,checkin_date),
  foreign key(challenge_id,user_id) references public.challenge_members(challenge_id,user_id) on delete cascade
);
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(), reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check(target_type in ('post','comment','profile','meetup')),
  target_id uuid not null, reason text not null, created_at timestamptz not null default now()
);
create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade, blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(), primary key(blocker_id,blocked_id), check(blocker_id<>blocked_id)
);
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(), recipient_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null, kind text not null,
  post_id uuid references public.posts(id) on delete cascade, read_at timestamptz, created_at timestamptz not null default now()
);

create index if not exists posts_created_idx on public.posts(created_at desc);
create index if not exists posts_user_created_idx on public.posts(user_id,created_at desc);
create index if not exists meetups_topic_idx on public.meetups(topic,status);
create index if not exists challenges_dates_idx on public.challenges(starts_on,ends_on);
create index if not exists comments_post_idx on public.comments(post_id,created_at);

-- RLS: any future private-group content must be checked through membership.
create or replace function public.is_active_meetup_member(target_meetup uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.meetup_members m where m.meetup_id=target_meetup and m.user_id=auth.uid() and m.status='active') $$;
create or replace function public.is_meetup_manager(target_meetup uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.meetup_members m where m.meetup_id=target_meetup and m.user_id=auth.uid() and m.status='active' and m.role in ('host','moderator')) $$;
create or replace function public.is_challenge_member(target_challenge uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.challenge_members m where m.challenge_id=target_challenge and m.user_id=auth.uid()) $$;

do $$ declare t text; begin
  foreach t in array array['profiles','posts','post_media','post_topics','comments','likes','follows','meetups','meetup_members','meetup_posts','meetup_events','event_rsvps','challenges','challenge_members','challenge_checkins','reports','blocks','notifications'] loop
    execute format('alter table public.%I enable row level security',t);
  end loop;
end $$;

drop policy if exists "profiles read" on public.profiles;
create policy "profiles read" on public.profiles for select using(true);
drop policy if exists "profile owner update" on public.profiles;
create policy "profile owner update" on public.profiles for update using(auth.uid()=id) with check(auth.uid()=id);
drop policy if exists "posts visible" on public.posts;
create policy "posts visible" on public.posts for select using((visibility='public' or auth.uid()=user_id or exists(select 1 from public.follows f where f.follower_id=auth.uid() and f.followed_id=user_id)) and not exists(select 1 from public.blocks b where (b.blocker_id=auth.uid() and b.blocked_id=user_id) or (b.blocker_id=user_id and b.blocked_id=auth.uid())));
drop policy if exists "post owner insert" on public.posts;
create policy "post owner insert" on public.posts for insert with check(auth.uid()=user_id);
drop policy if exists "post owner update" on public.posts;
create policy "post owner update" on public.posts for update using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "post owner delete" on public.posts;
create policy "post owner delete" on public.posts for delete using(auth.uid()=user_id);
drop policy if exists "post media visible" on public.post_media;
create policy "post media visible" on public.post_media for select using(exists(select 1 from public.posts p where p.id=post_id));
drop policy if exists "post media owner write" on public.post_media;
create policy "post media owner write" on public.post_media for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "post topics visible" on public.post_topics;
create policy "post topics visible" on public.post_topics for select using(exists(select 1 from public.posts p where p.id=post_id));
drop policy if exists "post topics owner write" on public.post_topics;
create policy "post topics owner write" on public.post_topics for all using(exists(select 1 from public.posts p where p.id=post_id and p.user_id=auth.uid())) with check(exists(select 1 from public.posts p where p.id=post_id and p.user_id=auth.uid()));
drop policy if exists "comments visible" on public.comments;
create policy "comments visible" on public.comments for select using(exists(select 1 from public.posts p where p.id=post_id));
drop policy if exists "comment insert self" on public.comments;
create policy "comment insert self" on public.comments for insert with check(auth.uid()=user_id and exists(select 1 from public.posts p where p.id=post_id));
drop policy if exists "comment owner delete" on public.comments;
create policy "comment owner delete" on public.comments for delete using(auth.uid()=user_id);
drop policy if exists "likes visible" on public.likes;
create policy "likes visible" on public.likes for select using(exists(select 1 from public.posts p where p.id=post_id));
drop policy if exists "like as self" on public.likes;
create policy "like as self" on public.likes for insert with check(auth.uid()=user_id);
drop policy if exists "unlike as self" on public.likes;
create policy "unlike as self" on public.likes for delete using(auth.uid()=user_id);
drop policy if exists "follows visible" on public.follows;
create policy "follows visible" on public.follows for select using(true);
drop policy if exists "follow as self" on public.follows;
create policy "follow as self" on public.follows for insert with check(auth.uid()=follower_id);
drop policy if exists "unfollow as self" on public.follows;
create policy "unfollow as self" on public.follows for delete using(auth.uid()=follower_id);

drop policy if exists "meetups public or member" on public.meetups;
create policy "meetups public or member" on public.meetups for select using(join_policy='public' or public.is_active_meetup_member(id));
drop policy if exists "meetup create self" on public.meetups;
create policy "meetup create self" on public.meetups for insert with check(auth.uid()=host_id);
drop policy if exists "meetup manager update" on public.meetups;
create policy "meetup manager update" on public.meetups for update using(public.is_meetup_manager(id)) with check(public.is_meetup_manager(id));
drop policy if exists "meetup manager delete" on public.meetups;
create policy "meetup manager delete" on public.meetups for delete using(public.is_meetup_manager(id));
drop policy if exists "members visible to members" on public.meetup_members;
create policy "members visible to members" on public.meetup_members for select using(auth.uid()=user_id or public.is_active_meetup_member(meetup_id));
drop policy if exists "request own membership" on public.meetup_members;
create policy "request own membership" on public.meetup_members for insert with check(auth.uid()=user_id and (status='pending' or exists(select 1 from public.meetups g where g.id=meetup_id and g.join_policy='public' and status='active')));
drop policy if exists "member leave or manager approval" on public.meetup_members;
create policy "member leave or manager approval" on public.meetup_members for update using(auth.uid()=user_id or public.is_meetup_manager(meetup_id)) with check(auth.uid()=user_id or public.is_meetup_manager(meetup_id));
drop policy if exists "member leave self" on public.meetup_members;
create policy "member leave self" on public.meetup_members for delete using(auth.uid()=user_id or public.is_meetup_manager(meetup_id));
drop policy if exists "meetup posts member read" on public.meetup_posts;
create policy "meetup posts member read" on public.meetup_posts for select using(public.is_active_meetup_member(meetup_id));
drop policy if exists "meetup posts member create" on public.meetup_posts;
create policy "meetup posts member create" on public.meetup_posts for insert with check(auth.uid()=user_id and public.is_active_meetup_member(meetup_id));
drop policy if exists "meetup posts author or manager update" on public.meetup_posts;
create policy "meetup posts author or manager update" on public.meetup_posts for update using(auth.uid()=user_id or public.is_meetup_manager(meetup_id)) with check(auth.uid()=user_id or public.is_meetup_manager(meetup_id));
drop policy if exists "meetup posts author or manager delete" on public.meetup_posts;
create policy "meetup posts author or manager delete" on public.meetup_posts for delete using(auth.uid()=user_id or public.is_meetup_manager(meetup_id));
drop policy if exists "meetup events member read" on public.meetup_events;
create policy "meetup events member read" on public.meetup_events for select using(public.is_active_meetup_member(meetup_id));
drop policy if exists "meetup events manager write" on public.meetup_events;
create policy "meetup events manager write" on public.meetup_events for all using(public.is_meetup_manager(meetup_id)) with check(public.is_meetup_manager(meetup_id));
drop policy if exists "event rsvps member read" on public.event_rsvps;
create policy "event rsvps member read" on public.event_rsvps for select using(exists(select 1 from public.meetup_events e where e.id=event_id and public.is_active_meetup_member(e.meetup_id)));
drop policy if exists "rsvp self write" on public.event_rsvps;
create policy "rsvp self write" on public.event_rsvps for all using(auth.uid()=user_id) with check(auth.uid()=user_id and exists(select 1 from public.meetup_events e where e.id=event_id and public.is_active_meetup_member(e.meetup_id)));

drop policy if exists "challenges readable" on public.challenges;
create policy "challenges readable" on public.challenges for select using(true);
drop policy if exists "challenge owner create" on public.challenges;
create policy "challenge owner create" on public.challenges for insert with check(auth.uid()=creator_id and paid=false);
drop policy if exists "challenge owner update" on public.challenges;
create policy "challenge owner update" on public.challenges for update using(auth.uid()=creator_id) with check(auth.uid()=creator_id and paid=false);
drop policy if exists "challenge owner delete" on public.challenges;
create policy "challenge owner delete" on public.challenges for delete using(auth.uid()=creator_id);
drop policy if exists "challenge members visible" on public.challenge_members;
create policy "challenge members visible" on public.challenge_members for select using(true);
drop policy if exists "join challenge self" on public.challenge_members;
create policy "join challenge self" on public.challenge_members for insert with check(auth.uid()=user_id);
drop policy if exists "leave challenge self" on public.challenge_members;
create policy "leave challenge self" on public.challenge_members for delete using(auth.uid()=user_id);
drop policy if exists "checkins member read" on public.challenge_checkins;
create policy "checkins member read" on public.challenge_checkins for select using(public.is_challenge_member(challenge_id));
drop policy if exists "checkin member own write" on public.challenge_checkins;
create policy "checkin member own write" on public.challenge_checkins for all using(auth.uid()=user_id and public.is_challenge_member(challenge_id)) with check(auth.uid()=user_id and public.is_challenge_member(challenge_id));
drop policy if exists "report as self" on public.reports;
create policy "report as self" on public.reports for insert with check(auth.uid()=reporter_id);
drop policy if exists "reporter read own" on public.reports;
create policy "reporter read own" on public.reports for select using(auth.uid()=reporter_id);
drop policy if exists "blocks private to blocker" on public.blocks;
create policy "blocks private to blocker" on public.blocks for all using(auth.uid()=blocker_id) with check(auth.uid()=blocker_id);
drop policy if exists "notifications private" on public.notifications;
create policy "notifications private" on public.notifications for select using(auth.uid()=recipient_id);
drop policy if exists "notifications mark read" on public.notifications;
create policy "notifications mark read" on public.notifications for update using(auth.uid()=recipient_id) with check(auth.uid()=recipient_id);

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('moa-media','moa-media',false,52428800,array['image/jpeg','image/png','image/webp','image/heic','video/mp4','video/quicktime','video/webm'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "moa media read" on storage.objects;
create policy "moa media read" on storage.objects for select to authenticated using(bucket_id='moa-media' and (exists(select 1 from public.post_media pm join public.posts p on p.id=pm.post_id where pm.storage_path=name and (p.visibility='public' or p.user_id=auth.uid() or exists(select 1 from public.follows f where f.follower_id=auth.uid() and f.followed_id=p.user_id))) or exists(select 1 from public.challenge_checkins ci where ci.media_path=name and public.is_challenge_member(ci.challenge_id))));
drop policy if exists "moa media upload own folder" on storage.objects;
create policy "moa media upload own folder" on storage.objects for insert to authenticated with check(bucket_id='moa-media' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "moa media update own folder" on storage.objects;
create policy "moa media update own folder" on storage.objects for update to authenticated using(bucket_id='moa-media' and (storage.foldername(name))[1]=auth.uid()::text) with check(bucket_id='moa-media' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "moa media delete own folder" on storage.objects;
create policy "moa media delete own folder" on storage.objects for delete to authenticated using(bucket_id='moa-media' and (storage.foldername(name))[1]=auth.uid()::text);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,username,display_name,language) values(new.id,coalesce(new.raw_user_meta_data->>'username','member_'||left(new.id::text,8)),coalesce(new.raw_user_meta_data->>'display_name',''),'en') on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.add_meetup_host() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.meetup_members(meetup_id,user_id,role,status) values(new.id,new.host_id,'host','active') on conflict(meetup_id,user_id) do nothing; return new; end; $$;
drop trigger if exists on_meetup_created_add_host on public.meetups;
create trigger on_meetup_created_add_host after insert on public.meetups for each row execute function public.add_meetup_host();

