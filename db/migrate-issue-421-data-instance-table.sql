-- Issue #421 (task 2): normalize the per-instance name + display order out of
-- the `data` table into a `data_instance` table referenced by a foreign key.
--
-- Run once per deployment, AFTER db/migrate-issue-421-rename-data-new-to-data.sql.
-- Atomic: the whole change succeeds or rolls back.

BEGIN;

CREATE TABLE public.data_instance (
    data_instance_id      integer NOT NULL,
    data_instance_dataset integer NOT NULL REFERENCES public.dataset(dataset_id) ON DELETE CASCADE,
    data_instance_name    text NOT NULL,
    data_instance_order   integer
);
CREATE SEQUENCE public.data_instance_data_instance_id_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE public.data_instance_data_instance_id_seq OWNED BY public.data_instance.data_instance_id;
ALTER TABLE ONLY public.data_instance
    ALTER COLUMN data_instance_id SET DEFAULT nextval('public.data_instance_data_instance_id_seq'::regclass);
ALTER TABLE ONLY public.data_instance ADD CONSTRAINT data_instance_pkey PRIMARY KEY (data_instance_id);
ALTER TABLE ONLY public.data_instance ADD CONSTRAINT data_instance_dataset_name_key UNIQUE (data_instance_dataset, data_instance_name);
ALTER TABLE public.data_instance OWNER TO agrammon;
ALTER TABLE public.data_instance_data_instance_id_seq OWNER TO agrammon;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.data_instance TO agrammon_user;
GRANT SELECT,UPDATE ON SEQUENCE public.data_instance_data_instance_id_seq TO agrammon_user;

-- backfill one instance row per (dataset, name); GROUP BY collapses any
-- order drift that the old per-row data_instance_order could have introduced.
INSERT INTO public.data_instance (data_instance_dataset, data_instance_name, data_instance_order)
     SELECT data_dataset, data_instance, MAX(data_instance_order)
       FROM public.data
      WHERE data_instance IS NOT NULL
   GROUP BY data_dataset, data_instance;

ALTER TABLE public.data ADD COLUMN data_instance_id integer;
UPDATE public.data d
   SET data_instance_id = i.data_instance_id
  FROM public.data_instance i
 WHERE d.data_dataset  = i.data_instance_dataset
   AND d.data_instance = i.data_instance_name;

DROP VIEW public.data_view;
ALTER TABLE public.data DROP CONSTRAINT data_data_var_key;
ALTER TABLE public.data DROP COLUMN data_instance;
ALTER TABLE public.data DROP COLUMN data_instance_order;
ALTER TABLE public.data ADD CONSTRAINT data_data_var_key UNIQUE (data_var, data_instance_id, data_dataset);
ALTER TABLE ONLY public.data ADD CONSTRAINT data_data_instance_id_fkey
    FOREIGN KEY (data_instance_id) REFERENCES public.data_instance(data_instance_id) ON DELETE CASCADE;

CREATE VIEW public.data_view AS
 SELECT d.data_id, d.data_dataset,
    COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var) AS data_var,
    d.data_val, i.data_instance_order, d.data_comment
   FROM (public.data d LEFT JOIN public.data_instance i ON ((d.data_instance_id = i.data_instance_id)))
  ORDER BY d.data_dataset, COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var);
ALTER TABLE public.data_view OWNER TO agrammon;
GRANT SELECT ON TABLE public.data_view TO agrammon_user;

COMMIT;
