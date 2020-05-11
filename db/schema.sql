--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: dataset_name2id(text, text); Type: FUNCTION; Schema: public; Owner: agrammon
--

CREATE FUNCTION public.dataset_name2id(username text, name text) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT dataset_id FROM dataset WHERE dataset_name = $2 AND dataset_pers = pers_email2id($1)$_$;


ALTER FUNCTION public.dataset_name2id(username text, name text) OWNER TO agrammon;

--
-- Name: pers_email2id(text); Type: FUNCTION; Schema: public; Owner: agrammon
--

CREATE FUNCTION public.pers_email2id(name text) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT pers_id FROM pers WHERE pers_email = $1 $_$;


ALTER FUNCTION public.pers_email2id(name text) OWNER TO agrammon;

--
-- Name: tag_name2id(text, text); Type: FUNCTION; Schema: public; Owner: agrammon
--

CREATE FUNCTION public.tag_name2id(username text, name text) RETURNS integer
    LANGUAGE sql STABLE
    AS $_$SELECT tag_id FROM tag WHERE tag_name = $2 AND tag_pers = pers_email2id($1)$_$;


ALTER FUNCTION public.tag_name2id(username text, name text) OWNER TO agrammon;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: data_new; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.data_new (
    data_id integer NOT NULL,
    data_dataset integer NOT NULL,
    data_var text NOT NULL,
    data_instance text,
    data_val text,
    data_instance_order integer,
    data_comment text
);


ALTER TABLE public.data_new OWNER TO agrammon;

--
-- Name: dataset; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.dataset (
    dataset_id integer NOT NULL,
    dataset_name text NOT NULL,
    dataset_pers integer NOT NULL,
    dataset_mod_date timestamp without time zone DEFAULT now(),
    dataset_version text DEFAULT '2.0'::text,
    dataset_comment text,
    dataset_model text,
    dataset_readonly boolean DEFAULT false,
    CONSTRAINT dataset_name_empty CHECK ((dataset_name !~ '^\s*$'::text))
);


ALTER TABLE public.dataset OWNER TO agrammon;

--
-- Name: pers; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.pers (
    pers_id integer NOT NULL,
    pers_email text NOT NULL,
    pers_first text,
    pers_last text,
    pers_password text NOT NULL,
    pers_org text,
    pers_last_login timestamp without time zone,
    pers_created timestamp without time zone DEFAULT now(),
    pers_role integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.pers OWNER TO agrammon;

--
-- Name: all_data; Type: VIEW; Schema: public; Owner: agrammon
--

CREATE VIEW public.all_data AS
 SELECT pers.pers_email,
    dataset.dataset_name,
    data_new.data_var,
    data_new.data_val
   FROM ((public.pers
     JOIN public.dataset ON ((dataset.dataset_pers = pers.pers_id)))
     JOIN public.data_new ON ((data_new.data_dataset = dataset.dataset_id)))
  ORDER BY pers.pers_email, dataset.dataset_name, data_new.data_var;


ALTER TABLE public.all_data OWNER TO agrammon;

--
-- Name: all_datasets; Type: VIEW; Schema: public; Owner: agrammon
--

CREATE VIEW public.all_datasets AS
 SELECT pers.pers_email,
    dataset.dataset_id,
    dataset.dataset_name,
    dataset.dataset_mod_date,
    dataset.dataset_version
   FROM (public.pers
     JOIN public.dataset ON ((dataset.dataset_pers = pers.pers_id)))
  ORDER BY pers.pers_email, dataset.dataset_name;


ALTER TABLE public.all_datasets OWNER TO agrammon;

--
-- Name: branches; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.branches (
    branches_id integer NOT NULL,
    branches_var integer NOT NULL,
    branches_data numeric[],
    branches_options text[]
);


ALTER TABLE public.branches OWNER TO agrammon;

--
-- Name: branches_branches_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.branches_branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.branches_branches_id_seq OWNER TO agrammon;

--
-- Name: branches_branches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.branches_branches_id_seq OWNED BY public.branches.branches_id;


--
-- Name: data_new_data_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.data_new_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.data_new_data_id_seq OWNER TO agrammon;

--
-- Name: data_new_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.data_new_data_id_seq OWNED BY public.data_new.data_id;


--
-- Name: data_view; Type: VIEW; Schema: public; Owner: agrammon
--

CREATE VIEW public.data_view AS
 SELECT data.data_id,
    data.data_dataset,
    COALESCE(replace(data.data_var, '[]'::text, (('['::text || data.data_instance) || ']'::text)), data.data_var) AS data_var,
    data.data_val,
    data.data_instance_order,
    data.data_comment
   FROM public.data_new data
  ORDER BY data.data_dataset, COALESCE(replace(data.data_var, '[]'::text, (('['::text || data.data_instance) || ']'::text)), data.data_var);


ALTER TABLE public.data_view OWNER TO agrammon;

--
-- Name: dataset_dataset_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.dataset_dataset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dataset_dataset_id_seq OWNER TO agrammon;

--
-- Name: dataset_dataset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.dataset_dataset_id_seq OWNED BY public.dataset.dataset_id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.news (
    news_id integer NOT NULL,
    news_newsty integer NOT NULL,
    news_date date DEFAULT now(),
    news_text text
);


ALTER TABLE public.news OWNER TO agrammon;

--
-- Name: news_news_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.news_news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.news_news_id_seq OWNER TO agrammon;

--
-- Name: news_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.news_news_id_seq OWNED BY public.news.news_id;


--
-- Name: newsty; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.newsty (
    newsty_id integer NOT NULL,
    newsty_name text
);


ALTER TABLE public.newsty OWNER TO agrammon;

--
-- Name: newsty_newsty_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.newsty_newsty_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.newsty_newsty_id_seq OWNER TO agrammon;

--
-- Name: newsty_newsty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.newsty_newsty_id_seq OWNED BY public.newsty.newsty_id;


--
-- Name: pers_pers_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.pers_pers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pers_pers_id_seq OWNER TO agrammon;

--
-- Name: pers_pers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.pers_pers_id_seq OWNED BY public.pers.pers_id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.role (
    role_id integer NOT NULL,
    role_name text NOT NULL
);


ALTER TABLE public.role OWNER TO agrammon;

--
-- Name: role_role_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.role_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_role_id_seq OWNER TO agrammon;

--
-- Name: role_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.role_role_id_seq OWNED BY public.role.role_id;


--
-- Name: tag; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.tag (
    tag_id integer NOT NULL,
    tag_name text NOT NULL,
    tag_pers integer NOT NULL
);


ALTER TABLE public.tag OWNER TO agrammon;

--
-- Name: tag_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.tag_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tag_tag_id_seq OWNER TO agrammon;

--
-- Name: tag_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.tag_tag_id_seq OWNED BY public.tag.tag_id;


--
-- Name: tagds; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.tagds (
    tagds_id integer NOT NULL,
    tagds_tag integer NOT NULL,
    tagds_dataset integer NOT NULL
);


ALTER TABLE public.tagds OWNER TO agrammon;

--
-- Name: tagds_tagds_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.tagds_tagds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tagds_tagds_id_seq OWNER TO agrammon;

--
-- Name: tagds_tagds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.tagds_tagds_id_seq OWNED BY public.tagds.tagds_id;


--
-- Name: branches branches_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.branches ALTER COLUMN branches_id SET DEFAULT nextval('public.branches_branches_id_seq'::regclass);


--
-- Name: data_new data_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_new ALTER COLUMN data_id SET DEFAULT nextval('public.data_new_data_id_seq'::regclass);


--
-- Name: dataset dataset_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.dataset ALTER COLUMN dataset_id SET DEFAULT nextval('public.dataset_dataset_id_seq'::regclass);


--
-- Name: news news_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.news ALTER COLUMN news_id SET DEFAULT nextval('public.news_news_id_seq'::regclass);


--
-- Name: newsty newsty_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.newsty ALTER COLUMN newsty_id SET DEFAULT nextval('public.newsty_newsty_id_seq'::regclass);


--
-- Name: pers pers_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.pers ALTER COLUMN pers_id SET DEFAULT nextval('public.pers_pers_id_seq'::regclass);


--
-- Name: role role_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.role ALTER COLUMN role_id SET DEFAULT nextval('public.role_role_id_seq'::regclass);


--
-- Name: tag tag_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tag ALTER COLUMN tag_id SET DEFAULT nextval('public.tag_tag_id_seq'::regclass);


--
-- Name: tagds tagds_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tagds ALTER COLUMN tagds_id SET DEFAULT nextval('public.tagds_tagds_id_seq'::regclass);


--
-- Name: branches branches_branches_var_key; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_branches_var_key UNIQUE (branches_var);


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (branches_id);


--
-- Name: data_new data_new_data_var_key; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_new
    ADD CONSTRAINT data_new_data_var_key UNIQUE (data_var, data_instance, data_dataset);


--
-- Name: data_new data_new_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_new
    ADD CONSTRAINT data_new_pkey PRIMARY KEY (data_id);


--
-- Name: dataset dataset_dataset_name_key; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.dataset
    ADD CONSTRAINT dataset_dataset_name_key UNIQUE (dataset_name, dataset_pers, dataset_model);


--
-- Name: dataset dataset_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (dataset_id);


--
-- Name: news news_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_pkey PRIMARY KEY (news_id);


--
-- Name: newsty newsty_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.newsty
    ADD CONSTRAINT newsty_pkey PRIMARY KEY (newsty_id);


--
-- Name: pers pers_pers_email_key; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.pers
    ADD CONSTRAINT pers_pers_email_key UNIQUE (pers_email);


--
-- Name: pers pers_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.pers
    ADD CONSTRAINT pers_pkey PRIMARY KEY (pers_id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (role_id);


--
-- Name: tag tag_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (tag_id);


--
-- Name: tag tag_tag_name_key; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_tag_name_key UNIQUE (tag_name, tag_pers);


--
-- Name: tagds tagds_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tagds
    ADD CONSTRAINT tagds_pkey PRIMARY KEY (tagds_id);


--
-- Name: data_new_data_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX data_new_data_dataset ON public.data_new USING btree (data_dataset);


--
-- Name: data_new_data_id_data_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX data_new_data_id_data_dataset ON public.data_new USING btree (data_id, data_dataset);


--
-- Name: dataset_dataset_pers; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX dataset_dataset_pers ON public.dataset USING btree (dataset_pers);


--
-- Name: tagds_tagds_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX tagds_tagds_dataset ON public.tagds USING btree (tagds_dataset);


--
-- Name: branches branches_branches_var_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_branches_var_fkey FOREIGN KEY (branches_var) REFERENCES public.data_new(data_id) ON DELETE CASCADE;


--
-- Name: data_new data_new_data_dataset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_new
    ADD CONSTRAINT data_new_data_dataset_fkey FOREIGN KEY (data_dataset) REFERENCES public.dataset(dataset_id) ON DELETE CASCADE;


--
-- Name: dataset dataset_dataset_pers_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.dataset
    ADD CONSTRAINT dataset_dataset_pers_fkey FOREIGN KEY (dataset_pers) REFERENCES public.pers(pers_id);


--
-- Name: news news_news_newsty_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_news_newsty_fkey FOREIGN KEY (news_newsty) REFERENCES public.newsty(newsty_id);


--
-- Name: pers pers_pers_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.pers
    ADD CONSTRAINT pers_pers_role_fkey FOREIGN KEY (pers_role) REFERENCES public.role(role_id);


--
-- Name: tag tag_tag_pers_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_tag_pers_fkey FOREIGN KEY (tag_pers) REFERENCES public.pers(pers_id);


--
-- Name: tagds tagds_tagds_dataset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tagds
    ADD CONSTRAINT tagds_tagds_dataset_fkey FOREIGN KEY (tagds_dataset) REFERENCES public.dataset(dataset_id) ON DELETE CASCADE;


--
-- Name: tagds tagds_tagds_tag_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tagds
    ADD CONSTRAINT tagds_tagds_tag_fkey FOREIGN KEY (tagds_tag) REFERENCES public.tag(tag_id) ON DELETE CASCADE;


--
-- Name: FUNCTION tag_name2id(username text, name text); Type: ACL; Schema: public; Owner: agrammon
--

GRANT ALL ON FUNCTION public.tag_name2id(username text, name text) TO agrammon_user;


--
-- Name: TABLE data_new; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.data_new TO agrammon_user;


--
-- Name: TABLE dataset; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.dataset TO agrammon_user;


--
-- Name: TABLE pers; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.pers TO agrammon_user;


--
-- Name: TABLE branches; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.branches TO agrammon_user;


--
-- Name: SEQUENCE branches_branches_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,UPDATE ON SEQUENCE public.branches_branches_id_seq TO agrammon_user;


--
-- Name: SEQUENCE data_new_data_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,UPDATE ON SEQUENCE public.data_new_data_id_seq TO agrammon_user;


--
-- Name: TABLE data_view; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT ON TABLE public.data_view TO agrammon_user;


--
-- Name: SEQUENCE dataset_dataset_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,UPDATE ON SEQUENCE public.dataset_dataset_id_seq TO agrammon_user;


--
-- Name: TABLE news; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT ON TABLE public.news TO agrammon_user;


--
-- Name: TABLE newsty; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT ON TABLE public.newsty TO agrammon_user;


--
-- Name: SEQUENCE pers_pers_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,UPDATE ON SEQUENCE public.pers_pers_id_seq TO agrammon_user;


--
-- Name: TABLE role; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT ON TABLE public.role TO agrammon_user;


--
-- Name: TABLE tag; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tag TO agrammon_user;


--
-- Name: SEQUENCE tag_tag_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT ALL ON SEQUENCE public.tag_tag_id_seq TO agrammon_user;


--
-- Name: TABLE tagds; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tagds TO agrammon_user;


--
-- Name: SEQUENCE tagds_tagds_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT ALL ON SEQUENCE public.tagds_tagds_id_seq TO agrammon_user;


--
-- PostgreSQL database dump complete
--