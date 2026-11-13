# MOA MVP

MOA is a mobile-first social app for discovering people through short video and connecting through text and photo posts. The MVP has five destinations: Home, Shorts, Create, Explore, and Profile. Standalone groups are deferred; interest filters organize posts and videos instead.

## Prototype

Open `outputs/index.html` in a browser. The prototype includes an interest-filtered Explore feed, a dedicated Shorts collection, post composer, comments, profile, and settings. Posts are currently held in page memory; this is not yet a multi-user backend.

## Supabase setup

1. Create a Supabase project and configure Auth providers (Google, email, Kakao, Apple) in Supabase and each provider console.
2. Run `supabase/schema.sql` in the Supabase SQL editor.
3. The schema creates a private `post-media` Storage bucket (50 MB max; common image/video types) and policies for authenticated reads and owner-only writes under `{user_id}/...`.
4. Connect the client using the project URL and publishable/anon key via environment configuration. Never expose the `service_role` key in browser code or this public repository.
5. Replace prototype state with authenticated database queries and Storage uploads before relying on cross-device persistence.

The browser prototype does not currently authenticate users or persist posts remotely. Social sign-in, remote media storage, and cross-device sync need a Supabase project and provider credentials.

