create table public.lots (
  code text primary key,
  parent_code text references public.lots(code) on delete cascade,
  seed boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.events (
  id bigint generated always as identity primary key,
  lot_code text not null references public.lots(code) on delete cascade,
  stage smallint not null check (stage between 0 and 3),
  action text not null,
  actor text,
  gap boolean not null default false,
  seed boolean not null default false,
  created_at timestamptz not null default now()
);
create index on public.events(lot_code);
create table public.lookups (
  id bigint generated always as identity primary key,
  code text not null,
  resultado text not null check (resultado in ('confirmada','lacuna','transito','inexistente')),
  created_at timestamptz not null default now()
);
create table public.alerts (
  id bigint generated always as identity primary key,
  code text not null,
  created_at timestamptz not null default now()
);

alter table public.lots enable row level security;
alter table public.events enable row level security;
alter table public.lookups enable row level security;
alter table public.alerts enable row level security;

create policy "ler lots" on public.lots for select to anon using (true);
create policy "ler events" on public.events for select to anon using (true);
create policy "ler lookups" on public.lookups for select to anon using (true);
create policy "ler alerts" on public.alerts for select to anon using (true);
create policy "criar lots" on public.lots for insert to anon with check (seed = false);
create policy "criar events" on public.events for insert to anon with check (seed = false);
create policy "criar lookups" on public.lookups for insert to anon with check (true);
create policy "criar alerts" on public.alerts for insert to anon with check (true);

create sequence public.lote_seq start 3;

create function public.proximo_codigo() returns text
language sql security definer set search_path = public as
$$ select 'SJ-A100-' || lpad(nextval('public.lote_seq')::text, 4, '0') $$;

create function public.reiniciar_simulacao() returns void
language plpgsql security definer set search_path = public as
$$ begin
  delete from events where seed = false;
  delete from lots where seed = false;
  delete from lookups;
  delete from alerts;
  perform setval('public.lote_seq', 2, true);
end $$;

grant execute on function public.proximo_codigo() to anon;
grant execute on function public.reiniciar_simulacao() to anon;

insert into public.lots (code, seed) values ('SJ-A100-0001', true), ('SJ-A100-0002', true);
insert into public.events (lot_code, stage, action, actor, seed, created_at) values
('SJ-A100-0001', 0, 'Extração e identificação', 'Mineradora A', true, '2026-10-05 09:10-03'),
('SJ-A100-0001', 1, 'Lote recebido', 'Beneficiamento B', true, '2026-10-08 14:30-03'),
('SJ-A100-0001', 2, 'Lote recebido', 'Distribuidora C', true, '2026-10-15 10:05-03'),
('SJ-A100-0001', 3, 'Lote recebido', 'Loja D', true, '2026-10-22 16:40-03'),
('SJ-A100-0002', 0, 'Extração e identificação', 'Mineradora A', true, '2026-10-06 08:20-03'),
('SJ-A100-0002', 1, 'Lote recebido', 'Beneficiamento B', true, '2026-10-09 11:00-03'),
('SJ-A100-0002', 3, 'Lote recebido', 'Loja D', true, '2026-10-27 15:15-03');
