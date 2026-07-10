-- AR Sales - Initial Multi-tenant Schema
-- Generated for Supabase/PostgreSQL

begin;

create extension if not exists "pgcrypto";

-- =========================================================
-- ENUMS
-- =========================================================
do $$ begin
  create type public.member_status as enum ('invited','active','suspended','removed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.customer_type as enum ('person','company');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.quote_status as enum ('draft','sent','viewed','under_review','approved','rejected','expired','converted','cancelled');
exception when duplicate_object then null; end $$;

-- =========================================================
-- HELPERS
-- =========================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =========================================================
-- PROFILES
-- =========================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  locale text not null default 'pt-BR',
  timezone text not null default 'America/Sao_Paulo',
  is_platform_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.email),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- =========================================================
-- COMPANIES / WORKSPACES
-- =========================================================
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id),
  legal_name text not null,
  trade_name text not null,
  document text,
  state_registration text,
  email text,
  phone text,
  whatsapp text,
  website text,
  logo_url text,
  primary_color text not null default '#2563EB',
  secondary_color text not null default '#06B6D4',
  accent_color text not null default '#8B5CF6',
  theme_mode text not null default 'dark' check (theme_mode in ('dark','light','system')),
  status text not null default 'active' check (status in ('active','trial','suspended','cancelled')),
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index if not exists companies_document_unique
  on public.companies (document)
  where document is not null and deleted_at is null;

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  description text,
  is_system_role boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, name)
);

create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  module text not null,
  description text
);

create table if not exists public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_id, permission_id)
);

create table if not exists public.company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid references public.roles(id) on delete set null,
  status public.member_status not null default 'active',
  permissions_override jsonb not null default '{}'::jsonb,
  invited_by uuid references public.profiles(id),
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, user_id)
);

create index if not exists company_members_user_company_idx
  on public.company_members (user_id, company_id)
  where status = 'active';

-- =========================================================
-- SECURITY HELPERS
-- =========================================================
create or replace function public.is_company_member(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.company_members cm
    where cm.company_id = target_company_id
      and cm.user_id = auth.uid()
      and cm.status = 'active'
  );
$$;

create or replace function public.is_company_owner(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.companies c
    where c.id = target_company_id
      and c.owner_user_id = auth.uid()
      and c.deleted_at is null
  );
$$;

create or replace function public.has_permission(target_company_id uuid, permission_code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_company_owner(target_company_id)
    or exists (
      select 1
      from public.company_members cm
      join public.roles r on r.id = cm.role_id
      join public.role_permissions rp on rp.role_id = r.id
      join public.permissions p on p.id = rp.permission_id
      where cm.company_id = target_company_id
        and cm.user_id = auth.uid()
        and cm.status = 'active'
        and p.code = permission_code
    )
    or coalesce((
      select (cm.permissions_override ->> permission_code)::boolean
      from public.company_members cm
      where cm.company_id = target_company_id
        and cm.user_id = auth.uid()
        and cm.status = 'active'
    ), false);
$$;

-- =========================================================
-- CUSTOMERS
-- =========================================================
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  responsible_user_id uuid references public.profiles(id) on delete set null,
  type public.customer_type not null default 'company',
  name text not null,
  legal_name text,
  document text,
  state_registration text,
  email text,
  phone text,
  whatsapp text,
  status text not null default 'active' check (status in ('lead','active','inactive','blocked')),
  notes text,
  tags text[] not null default '{}',
  custom_fields jsonb not null default '{}'::jsonb,
  version bigint not null default 1,
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists customers_company_name_idx on public.customers (company_id, name);
create index if not exists customers_company_document_idx on public.customers (company_id, document);
create index if not exists customers_company_status_idx on public.customers (company_id, status) where deleted_at is null;

create table if not exists public.customer_contacts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  name text not null,
  position text,
  email text,
  phone text,
  whatsapp text,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists customer_contacts_company_customer_idx
  on public.customer_contacts (company_id, customer_id)
  where deleted_at is null;

create table if not exists public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  type text not null default 'billing' check (type in ('billing','shipping','commercial','other')),
  street text,
  number text,
  complement text,
  district text,
  city text,
  state text,
  postal_code text,
  country text not null default 'BR',
  latitude numeric(10,7),
  longitude numeric(10,7),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- =========================================================
-- PRODUCTS / CATALOG
-- =========================================================
create table if not exists public.product_categories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  parent_id uuid references public.product_categories(id) on delete set null,
  name text not null,
  slug text,
  description text,
  image_url text,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (company_id, name)
);

create index if not exists product_categories_company_parent_idx
  on public.product_categories (company_id, parent_id)
  where deleted_at is null;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  category_id uuid references public.product_categories(id) on delete set null,
  name text not null,
  sku text,
  barcode text,
  short_description text,
  description text,
  technical_description text,
  cost_price numeric(14,2) not null default 0,
  sale_price numeric(14,2) not null default 0,
  stock_quantity numeric(14,3) not null default 0,
  unit text not null default 'UN',
  minimum_order_quantity numeric(14,3) not null default 1,
  active boolean not null default true,
  featured boolean not null default false,
  attributes jsonb not null default '{}'::jsonb,
  version bigint not null default 1,
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (company_id, sku)
);

create index if not exists products_company_name_idx on public.products (company_id, name);
create index if not exists products_company_category_idx on public.products (company_id, category_id) where deleted_at is null;
create index if not exists products_company_active_idx on public.products (company_id, active) where deleted_at is null;

create table if not exists public.product_media (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  type text not null check (type in ('image','video','manual','datasheet','other')),
  file_url text not null,
  title text,
  mime_type text,
  size_bytes bigint,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- =========================================================
-- PRICING
-- =========================================================
create table if not exists public.price_tables (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  description text,
  active boolean not null default true,
  valid_from date,
  valid_until date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (company_id, name)
);

create table if not exists public.price_table_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  price_table_id uuid not null references public.price_tables(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  price numeric(14,2) not null,
  minimum_price numeric(14,2),
  maximum_discount numeric(7,4) not null default 0,
  commission_percentage numeric(7,4) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (price_table_id, product_id)
);

-- =========================================================
-- QUOTE TEMPLATES / QUOTES
-- =========================================================
create table if not exists public.quote_templates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  description text,
  layout_json jsonb not null default '{}'::jsonb,
  header_json jsonb not null default '{}'::jsonb,
  footer_json jsonb not null default '{}'::jsonb,
  theme_json jsonb not null default '{}'::jsonb,
  is_default boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (company_id, name)
);

create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete restrict,
  seller_user_id uuid not null references public.profiles(id),
  price_table_id uuid references public.price_tables(id) on delete set null,
  template_id uuid references public.quote_templates(id) on delete set null,
  quote_number bigint not null,
  status public.quote_status not null default 'draft',
  currency char(3) not null default 'BRL',
  subtotal numeric(14,2) not null default 0,
  discount_total numeric(14,2) not null default 0,
  freight_total numeric(14,2) not null default 0,
  tax_total numeric(14,2) not null default 0,
  grand_total numeric(14,2) not null default 0,
  valid_until date,
  payment_terms text,
  delivery_terms text,
  notes text,
  internal_notes text,
  version bigint not null default 1,
  sent_at timestamptz,
  viewed_at timestamptz,
  approved_at timestamptz,
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (company_id, quote_number)
);

create index if not exists quotes_company_status_idx on public.quotes (company_id, status) where deleted_at is null;
create index if not exists quotes_company_customer_idx on public.quotes (company_id, customer_id) where deleted_at is null;
create index if not exists quotes_company_seller_idx on public.quotes (company_id, seller_user_id) where deleted_at is null;

create table if not exists public.quote_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  quote_id uuid not null references public.quotes(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  sku text,
  description text not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit text not null default 'UN',
  unit_price numeric(14,2) not null check (unit_price >= 0),
  discount_percentage numeric(7,4) not null default 0 check (discount_percentage >= 0 and discount_percentage <= 100),
  commission_percentage numeric(7,4) not null default 0 check (commission_percentage >= 0 and commission_percentage <= 100),
  line_subtotal numeric(14,2) generated always as (round(quantity * unit_price, 2)) stored,
  line_total numeric(14,2) generated always as (round(quantity * unit_price * (1 - discount_percentage / 100), 2)) stored,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists quote_items_company_quote_idx on public.quote_items (company_id, quote_id);

-- Keep quote totals synchronized
create or replace function public.recalculate_quote_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_quote_id uuid;
begin
  target_quote_id := coalesce(new.quote_id, old.quote_id);

  update public.quotes q
  set subtotal = coalesce(s.subtotal, 0),
      discount_total = coalesce(s.subtotal, 0) - coalesce(s.total, 0),
      grand_total = coalesce(s.total, 0) + q.freight_total + q.tax_total,
      updated_at = now(),
      version = q.version + 1
  from (
    select quote_id,
           sum(line_subtotal) as subtotal,
           sum(line_total) as total
    from public.quote_items
    where quote_id = target_quote_id
    group by quote_id
  ) s
  where q.id = target_quote_id;

  if not found then
    update public.quotes
    set subtotal = 0,
        discount_total = 0,
        grand_total = freight_total + tax_total,
        updated_at = now(),
        version = version + 1
    where id = target_quote_id;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_quote_items_recalculate on public.quote_items;
create trigger trg_quote_items_recalculate
after insert or update or delete on public.quote_items
for each row execute function public.recalculate_quote_totals();

-- =========================================================
-- UPDATED_AT TRIGGERS
-- =========================================================
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','companies','roles','company_members','customers','customer_contacts',
    'customer_addresses','product_categories','products','price_tables','price_table_items',
    'quote_templates','quotes','quote_items'
  ] loop
    execute format('drop trigger if exists trg_%I_updated_at on public.%I', t, t);
    execute format('create trigger trg_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
  end loop;
end $$;

-- =========================================================
-- RLS
-- =========================================================
alter table public.profiles enable row level security;
alter table public.companies enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.company_members enable row level security;
alter table public.customers enable row level security;
alter table public.customer_contacts enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.product_categories enable row level security;
alter table public.products enable row level security;
alter table public.product_media enable row level security;
alter table public.price_tables enable row level security;
alter table public.price_table_items enable row level security;
alter table public.quote_templates enable row level security;
alter table public.quotes enable row level security;
alter table public.quote_items enable row level security;

-- Profiles
create policy "profiles_select_self_or_shared_company"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.company_members me
    join public.company_members other on other.company_id = me.company_id
    where me.user_id = auth.uid()
      and me.status = 'active'
      and other.user_id = profiles.id
      and other.status = 'active'
  )
);

create policy "profiles_update_self"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Companies
create policy "companies_select_member"
on public.companies for select
to authenticated
using (owner_user_id = auth.uid() or public.is_company_member(id));

create policy "companies_insert_owner"
on public.companies for insert
to authenticated
with check (owner_user_id = auth.uid());

create policy "companies_update_owner_or_manager"
on public.companies for update
to authenticated
using (public.is_company_owner(id) or public.has_permission(id, 'company.manage'))
with check (public.is_company_owner(id) or public.has_permission(id, 'company.manage'));

-- Membership and roles
create policy "members_select_same_company"
on public.company_members for select
to authenticated
using (public.is_company_member(company_id) or public.is_company_owner(company_id));

create policy "members_manage"
on public.company_members for all
to authenticated
using (public.is_company_owner(company_id) or public.has_permission(company_id, 'company.manage_users'))
with check (public.is_company_owner(company_id) or public.has_permission(company_id, 'company.manage_users'));

create policy "roles_select_member"
on public.roles for select
to authenticated
using (public.is_company_member(company_id) or public.is_company_owner(company_id));

create policy "roles_manage"
on public.roles for all
to authenticated
using (public.is_company_owner(company_id) or public.has_permission(company_id, 'company.manage_roles'))
with check (public.is_company_owner(company_id) or public.has_permission(company_id, 'company.manage_roles'));

create policy "permissions_read_authenticated"
on public.permissions for select
to authenticated
using (true);

create policy "role_permissions_read_member"
on public.role_permissions for select
to authenticated
using (
  exists (
    select 1 from public.roles r
    where r.id = role_permissions.role_id
      and (public.is_company_member(r.company_id) or public.is_company_owner(r.company_id))
  )
);

create policy "role_permissions_manage"
on public.role_permissions for all
to authenticated
using (
  exists (
    select 1 from public.roles r
    where r.id = role_permissions.role_id
      and (public.is_company_owner(r.company_id) or public.has_permission(r.company_id, 'company.manage_roles'))
  )
)
with check (
  exists (
    select 1 from public.roles r
    where r.id = role_permissions.role_id
      and (public.is_company_owner(r.company_id) or public.has_permission(r.company_id, 'company.manage_roles'))
  )
);

-- Generic tenant policies
create policy "customers_select" on public.customers for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "customers_insert" on public.customers for insert to authenticated
with check (public.has_permission(company_id, 'customers.create'));
create policy "customers_update" on public.customers for update to authenticated
using (public.has_permission(company_id, 'customers.edit'))
with check (public.has_permission(company_id, 'customers.edit'));
create policy "customers_delete" on public.customers for delete to authenticated
using (public.has_permission(company_id, 'customers.delete'));

create policy "customer_contacts_select" on public.customer_contacts for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "customer_contacts_insert" on public.customer_contacts for insert to authenticated
with check (public.has_permission(company_id, 'customers.edit'));
create policy "customer_contacts_update" on public.customer_contacts for update to authenticated
using (public.has_permission(company_id, 'customers.edit'))
with check (public.has_permission(company_id, 'customers.edit'));
create policy "customer_contacts_delete" on public.customer_contacts for delete to authenticated
using (public.has_permission(company_id, 'customers.edit'));

create policy "customer_addresses_select" on public.customer_addresses for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "customer_addresses_insert" on public.customer_addresses for insert to authenticated
with check (public.has_permission(company_id, 'customers.edit'));
create policy "customer_addresses_update" on public.customer_addresses for update to authenticated
using (public.has_permission(company_id, 'customers.edit'))
with check (public.has_permission(company_id, 'customers.edit'));
create policy "customer_addresses_delete" on public.customer_addresses for delete to authenticated
using (public.has_permission(company_id, 'customers.edit'));

create policy "categories_select" on public.product_categories for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "categories_manage" on public.product_categories for all to authenticated
using (public.has_permission(company_id, 'products.manage'))
with check (public.has_permission(company_id, 'products.manage'));

create policy "products_select" on public.products for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "products_insert" on public.products for insert to authenticated
with check (public.has_permission(company_id, 'products.create'));
create policy "products_update" on public.products for update to authenticated
using (public.has_permission(company_id, 'products.edit'))
with check (public.has_permission(company_id, 'products.edit'));
create policy "products_delete" on public.products for delete to authenticated
using (public.has_permission(company_id, 'products.delete'));

create policy "product_media_select" on public.product_media for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "product_media_insert" on public.product_media for insert to authenticated
with check (public.has_permission(company_id, 'products.edit'));
create policy "product_media_update" on public.product_media for update to authenticated
using (public.has_permission(company_id, 'products.edit'))
with check (public.has_permission(company_id, 'products.edit'));
create policy "product_media_delete" on public.product_media for delete to authenticated
using (public.has_permission(company_id, 'products.edit'));

create policy "price_tables_select" on public.price_tables for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "price_tables_manage" on public.price_tables for all to authenticated
using (public.has_permission(company_id, 'pricing.manage'))
with check (public.has_permission(company_id, 'pricing.manage'));

create policy "price_table_items_select" on public.price_table_items for select to authenticated
using (public.is_company_member(company_id));
create policy "price_table_items_manage" on public.price_table_items for all to authenticated
using (public.has_permission(company_id, 'pricing.manage'))
with check (public.has_permission(company_id, 'pricing.manage'));

create policy "quote_templates_select" on public.quote_templates for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "quote_templates_manage" on public.quote_templates for all to authenticated
using (public.has_permission(company_id, 'quotes.manage_templates'))
with check (public.has_permission(company_id, 'quotes.manage_templates'));

create policy "quotes_select" on public.quotes for select to authenticated
using (public.is_company_member(company_id) and deleted_at is null);
create policy "quotes_insert" on public.quotes for insert to authenticated
with check (public.has_permission(company_id, 'quotes.create'));
create policy "quotes_update" on public.quotes for update to authenticated
using (public.has_permission(company_id, 'quotes.edit'))
with check (public.has_permission(company_id, 'quotes.edit'));
create policy "quotes_delete" on public.quotes for delete to authenticated
using (public.has_permission(company_id, 'quotes.delete'));

create policy "quote_items_select" on public.quote_items for select to authenticated
using (public.is_company_member(company_id));
create policy "quote_items_manage" on public.quote_items for all to authenticated
using (public.has_permission(company_id, 'quotes.edit'))
with check (public.has_permission(company_id, 'quotes.edit'));

-- =========================================================
-- PERMISSIONS SEED
-- =========================================================
insert into public.permissions (code, module, description) values
('company.manage','company','Editar dados e identidade da empresa'),
('company.manage_users','company','Gerenciar membros e convites'),
('company.manage_roles','company','Gerenciar cargos e permissões'),
('customers.view','customers','Visualizar clientes'),
('customers.create','customers','Cadastrar clientes'),
('customers.edit','customers','Editar clientes'),
('customers.delete','customers','Excluir clientes'),
('products.view','products','Visualizar produtos'),
('products.view_cost','products','Visualizar custo dos produtos'),
('products.create','products','Cadastrar produtos'),
('products.edit','products','Editar produtos'),
('products.delete','products','Excluir produtos'),
('products.manage','products','Gerenciar categorias e catálogo'),
('pricing.manage','pricing','Gerenciar tabelas de preço'),
('quotes.view','quotes','Visualizar orçamentos'),
('quotes.create','quotes','Criar orçamentos'),
('quotes.edit','quotes','Editar orçamentos'),
('quotes.delete','quotes','Excluir orçamentos'),
('quotes.approve','quotes','Aprovar orçamentos'),
('quotes.manage_templates','quotes','Gerenciar modelos de orçamento')
on conflict (code) do nothing;

-- =========================================================
-- CREATE DEFAULT ROLES WHEN COMPANY IS CREATED
-- =========================================================
create or replace function public.create_default_company_setup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_role_id uuid;
  seller_role_id uuid;
begin
  insert into public.roles (company_id, name, description, is_system_role)
  values (new.id, 'Administrador', 'Acesso administrativo ao workspace', true)
  returning id into admin_role_id;

  insert into public.roles (company_id, name, description, is_system_role)
  values (new.id, 'Vendedor', 'Acesso comercial padrão', true)
  returning id into seller_role_id;

  insert into public.role_permissions (role_id, permission_id)
  select admin_role_id, p.id from public.permissions p;

  insert into public.role_permissions (role_id, permission_id)
  select seller_role_id, p.id
  from public.permissions p
  where p.code in (
    'customers.view','customers.create','customers.edit',
    'products.view','quotes.view','quotes.create','quotes.edit'
  );

  insert into public.company_members (company_id, user_id, role_id, status, joined_at)
  values (new.id, new.owner_user_id, admin_role_id, 'active', now())
  on conflict (company_id, user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_create_default_company_setup on public.companies;
create trigger trg_create_default_company_setup
after insert on public.companies
for each row execute function public.create_default_company_setup();

commit;
