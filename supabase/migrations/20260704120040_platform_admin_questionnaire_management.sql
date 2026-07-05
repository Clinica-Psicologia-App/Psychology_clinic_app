-- Permite que o administrador global gerencie o catalogo de questionarios.
-- A leitura ativa para psicologos/pacientes permanece nas policies existentes.

CREATE POLICY questionnaires_select_platform_admin
  ON public.questionnaires
  FOR SELECT
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaires_insert_platform_admin
  ON public.questionnaires
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaires_update_platform_admin
  ON public.questionnaires
  FOR UPDATE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaires_delete_platform_admin
  ON public.questionnaires
  FOR DELETE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS questionnaire_versions_insert ON public.questionnaire_versions;
DROP POLICY IF EXISTS questionnaire_versions_update ON public.questionnaire_versions;
DROP POLICY IF EXISTS questionnaire_versions_delete ON public.questionnaire_versions;

CREATE POLICY questionnaire_versions_insert_platform_admin
  ON public.questionnaire_versions
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaire_versions_update_platform_admin
  ON public.questionnaire_versions
  FOR UPDATE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaire_versions_delete_platform_admin
  ON public.questionnaire_versions
  FOR DELETE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS question_categories_insert ON public.question_categories;
DROP POLICY IF EXISTS question_categories_update ON public.question_categories;
DROP POLICY IF EXISTS question_categories_delete ON public.question_categories;

CREATE POLICY question_categories_insert_platform_admin
  ON public.question_categories
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY question_categories_update_platform_admin
  ON public.question_categories
  FOR UPDATE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY question_categories_delete_platform_admin
  ON public.question_categories
  FOR DELETE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS questions_insert ON public.questions;
DROP POLICY IF EXISTS questions_update ON public.questions;
DROP POLICY IF EXISTS questions_delete ON public.questions;

CREATE POLICY questions_insert_platform_admin
  ON public.questions
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questions_update_platform_admin
  ON public.questions
  FOR UPDATE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questions_delete_platform_admin
  ON public.questions
  FOR DELETE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS question_category_items_insert ON public.question_category_items;
DROP POLICY IF EXISTS question_category_items_update ON public.question_category_items;
DROP POLICY IF EXISTS question_category_items_delete ON public.question_category_items;

CREATE POLICY question_category_items_insert_platform_admin
  ON public.question_category_items
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY question_category_items_update_platform_admin
  ON public.question_category_items
  FOR UPDATE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY question_category_items_delete_platform_admin
  ON public.question_category_items
  FOR DELETE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');
