-- Adds structured price-offer support to in-app chat messages.
-- JamUP connects musicians and venues around paid gigs, but the chat had
-- no first-class way to negotiate the rate — only free text. This lets
-- either side send a structured price offer ('offer' message type) that
-- the other party can Accept or Decline directly inside the conversation.
-- Additive only — existing 'user'/'system' rows are untouched.

alter table public.messages drop constraint if exists messages_type_check;
alter table public.messages add constraint messages_type_check
  check (type in ('user', 'system', 'offer'));

alter table public.messages add column if not exists offer_amount numeric;

alter table public.messages add column if not exists offer_unit text
  check (offer_unit in ('per_hour', 'per_day', 'fixed'));

alter table public.messages add column if not exists offer_status text
  check (offer_status in ('pending', 'accepted', 'declined'));
