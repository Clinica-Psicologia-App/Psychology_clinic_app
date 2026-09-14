-- Lote D / N20. Global published projection remains unchanged.
BEGIN;
CREATE OR REPLACE FUNCTION public.get_psychoeducation_journey()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  result JSONB;
BEGIN
  IF current_setting('role', true) IS DISTINCT FROM 'authenticated'
    OR auth.uid() IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Psychoeducation access denied';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles AS actor
    WHERE actor.id = auth.uid() AND actor.is_active IS TRUE
      AND actor.role::text IN ('patient', 'psychologist')
  ) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Psychoeducation access denied';
  END IF;
  SELECT COALESCE(jsonb_agg(m ORDER BY m.number), '[]'::jsonb)
  INTO result
  FROM (
    SELECT
      pm.id,
      pm.number,
      pm.stage,
      pm.title,
      pm.presentation,
      pm.closing,
      pm.accent_color,
      pm.cover_url,
      COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'title', card->>'title',
            'image_url', card->>'image_url',
            'patient_text', card->>'patient_text',
            'reflection', card->>'reflection',
            'exercise', card->>'exercise'
          )
        )
        FROM jsonb_array_elements(pm.cards) AS card
      ), '[]'::jsonb) AS cards
    FROM public.psychoeducation_modules pm
    WHERE pm.is_published
    ORDER BY pm.number
  ) m;

  RETURN result;
END;
$$;
-- Preserve owner/superuser powers; no legitimate direct server caller exists.
REVOKE EXECUTE ON FUNCTION public.get_psychoeducation_journey() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.get_psychoeducation_journey() TO authenticated;
COMMIT;