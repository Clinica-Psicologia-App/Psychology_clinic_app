-- GoTrue falha no login se confirmation_token etc. forem NULL (seed manual em auth.users).
-- https://github.com/supabase/auth/issues/1940
-- Apenas UPDATE (hosted Supabase não permite ALTER em auth.users).

UPDATE auth.users
SET
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change = COALESCE(email_change, '')
WHERE
  confirmation_token IS NULL
  OR recovery_token IS NULL
  OR email_change_token_new IS NULL
  OR email_change IS NULL;
