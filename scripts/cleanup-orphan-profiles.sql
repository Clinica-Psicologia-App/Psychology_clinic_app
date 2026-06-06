-- Perfis public.profiles sem auth.users (seed antiga / drift).
-- Execute no SQL Editor do Supabase APÓS revisar o SELECT.
-- Projeto: wxotrgmhevztoquqqmno (dev/staging apenas).

-- 1) Diagnóstico
SELECT p.id, p.email, p.role, p.clinic_id
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL
ORDER BY p.email;

-- 2) Pacientes ligados a profiles órfãos (revise antes de apagar)
SELECT pt.id AS patient_id, pt.profile_id, p.email
FROM public.patients pt
JOIN public.profiles p ON p.id = pt.profile_id
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL;

-- 3) Remoção (descomente só após revisar as listas acima)
-- DELETE FROM public.patients
-- WHERE profile_id IN (
--   SELECT p.id FROM public.profiles p
--   LEFT JOIN auth.users u ON u.id = p.id
--   WHERE u.id IS NULL
-- );
--
-- DELETE FROM public.profiles p
-- WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id);
