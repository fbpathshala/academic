-- Seed the new Academic Care admin allow-list from the existing project's super-admin identity.
-- This copies permission only; it does not change the legacy permissions table.
insert into public.academic_care_admins(user_id,role,is_active)
select p.user_id,'admin',true
from public.admin_user_permissions p
join auth.users u on u.id=p.user_id
where p.role_name='super_admin'
on conflict (user_id) do update set role='admin',is_active=true;
