# MOA 2.0 — Connect. Share. Experience.

Mobile-first social app concept centered on interest-based posts, meetups, and free challenges.

## Preview

Open [`outputs/index.html`](outputs/index.html) in a browser. It is a front-end prototype with sample content and browser-local interactions. Accounts, shared posts, media storage, private group access, and notifications are **not connected** to Supabase yet. Do not treat preview interactions as persisted multi-user data.

## Product scope

- Home: For You, Following, Latest; text, photo, and short-video posts; replies, likes, follows, reposts, saves, reports.
- Explore: one search for posts, meetups, and challenges, filtered by interests.
- Meetups: interest-based groups, public or approval-based joining, group posts, events, RSVP, and members.
- Challenges: free challenges, membership, dated check-ins, progress, and completion badges.
- Activities: joined groups, events, and challenges. Profile: interests, followers, and posts.
- English and Korean UI shell.

MOA 2.0 removes the dedicated Shorts feed and the Help Matching and Housing services. Short videos remain a media type within ordinary posts. Paid challenges, payments, realtime rooms/chat, and complex recommendations are deferred.

## Supabase preparation

1. Review `supabase/schema.sql` and apply it to a development Supabase project before production use.
2. Configure Auth, then provide the project URL and publishable key through the app's deployment configuration. Never place the `service_role` key in browser code or this public repository.
3. Connect the UI to Supabase Auth, Postgres, and Storage. The current HTML preview does not contain that client integration.
4. Validate RLS for visibility, author-only edits, meetup membership, event RSVP, challenge check-ins, reports, and blocks with multiple test accounts before exposing private group content.

The schema includes initial RLS policies and a private `moa-media` bucket. It has not been applied to or verified against the user's Supabase project. Review and migrate it in a development project first; application logic still needs to be wired to these tables.

## Preserved previous version

The pre-2.0 prototype is kept at `work/backups/moafans-pre-moa2.html` for rollback/reference. It is not the active product UI.

