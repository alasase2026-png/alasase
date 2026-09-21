-- =========================================================
-- قاعدة بيانات نهائية لموقع «العسسي»
-- الأسعار + الصور + العروض + الأسماء + التوفر أونلاين
-- =========================================================

-- 1) أعمدة إضافية للمنيو والعروض
alter table public.menu_items
  add column if not exists offer_old_price numeric default 0,
  add column if not exists offer_new_price numeric default 0,
  add column if not exists offer_discount numeric default 0,
  add column if not exists offer_start timestamptz,
  add column if not exists offer_end timestamptz,
  add column if not exists offer_image text,
  add column if not exists price_small numeric default 0,
  add column if not exists price_medium numeric default 0,
  add column if not exists price_large numeric default 0;

-- 2) التأكد من وجود الأعمدة الأساسية التي يستخدمها الموقع
alter table public.menu_items
  add column if not exists is_available boolean default true,
  add column if not exists is_offer boolean default false,
  add column if not exists has_sizes boolean default false,
  add column if not exists custom_sizes jsonb,
  add column if not exists image text,
  add column if not exists icon text,
  add column if not exists desc text;

-- 3) قيم افتراضية آمنة
update public.menu_items set is_available = true where is_available is null;
update public.menu_items set is_offer = false where is_offer is null;
update public.menu_items set has_sizes = false where has_sizes is null;

-- 4) تفعيل RLS على المنيو
alter table public.menu_items enable row level security;

-- حذف سياسات قديمة من هذا الإصدار
 drop policy if exists "alassi_public_read_menu_items" on public.menu_items;
 drop policy if exists "alassi_authenticated_insert_menu_items" on public.menu_items;
 drop policy if exists "alassi_authenticated_update_menu_items" on public.menu_items;
 drop policy if exists "alassi_authenticated_delete_menu_items" on public.menu_items;

-- الزبائن يستطيعون قراءة المنيو بدون تسجيل دخول
create policy "alassi_public_read_menu_items"
on public.menu_items
for select
to anon, authenticated
using (true);

-- حساب الإدارة المسجل يستطيع التعديل.
-- مهم: عطّل التسجيل العام من Supabase Authentication > Providers/Signups
-- حتى لا يتمكن مستخدم عادي من إنشاء حساب والدخول للوحة الإدارة.
create policy "alassi_authenticated_insert_menu_items"
on public.menu_items
for insert
to authenticated
with check (true);

create policy "alassi_authenticated_update_menu_items"
on public.menu_items
for update
to authenticated
using (true)
with check (true);

create policy "alassi_authenticated_delete_menu_items"
on public.menu_items
for delete
to authenticated
using (true);

-- 5) إعدادات المطعم
alter table public.restaurant_settings enable row level security;

drop policy if exists "alassi_public_read_settings" on public.restaurant_settings;
drop policy if exists "alassi_authenticated_update_settings" on public.restaurant_settings;

create policy "alassi_public_read_settings"
on public.restaurant_settings
for select
to anon, authenticated
using (true);

create policy "alassi_authenticated_update_settings"
on public.restaurant_settings
for update
to authenticated
using (true)
with check (true);

-- 6) إنشاء Storage Bucket للصور إذا لم يكن موجوداً
insert into storage.buckets (id, name, public)
values ('menu-images', 'menu-images', true)
on conflict (id) do update set public = true;

-- 7) سياسات صور الموقع
 drop policy if exists "alassi_public_read_menu_images" on storage.objects;
 drop policy if exists "alassi_authenticated_upload_menu_images" on storage.objects;
 drop policy if exists "alassi_authenticated_update_menu_images" on storage.objects;
 drop policy if exists "alassi_authenticated_delete_menu_images" on storage.objects;

create policy "alassi_public_read_menu_images"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'menu-images');

create policy "alassi_authenticated_upload_menu_images"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'menu-images');

create policy "alassi_authenticated_update_menu_images"
on storage.objects
for update
to authenticated
using (bucket_id = 'menu-images')
with check (bucket_id = 'menu-images');

create policy "alassi_authenticated_delete_menu_images"
on storage.objects
for delete
to authenticated
using (bucket_id = 'menu-images');

-- 8) تفعيل Realtime على الجداول (إذا لم تكن مضافة مسبقاً)
do $$
begin
  begin
    alter publication supabase_realtime add table public.menu_items;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.restaurant_settings;
  exception when duplicate_object then null;
  end;
end $$;

-- =========================================================
-- بعد تشغيل هذا الملف:
-- 1. Supabase > Authentication: أنشئ/استخدم حساب الإدارة فقط.
-- 2. عطّل التسجيل العام Signups إذا كنت لا تريد حسابات إضافية.
-- 3. ارفع index.html النهائي إلى GitHub Pages.
-- 4. ادخل لوحة الإدارة بالبريد وكلمة المرور.
-- =========================================================
