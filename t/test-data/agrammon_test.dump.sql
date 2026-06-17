--
-- PostgreSQL database dump
--

\restrict etJtfvqpC1gidDhHbLhpEhLE9bwgwFanhOi6yN73yveoYA1ivIM4Dlx6hSKZGIT

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: test; Type: SCHEMA; Schema: -; Owner: agrammon
--

CREATE SCHEMA test;


ALTER SCHEMA test OWNER TO agrammon;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: dataset_name2id(text, text); Type: FUNCTION; Schema: public; Owner: agrammon
--

CREATE FUNCTION public.dataset_name2id(username text, name text) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT dataset_id FROM dataset WHERE dataset_name = $2 AND dataset_pers = pers_email2id($1)$_$;


ALTER FUNCTION public.dataset_name2id(username text, name text) OWNER TO agrammon;

--
-- Name: dataset_name2id(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: agrammon
--

CREATE FUNCTION public.dataset_name2id(username text, name text, version text, guivariant text, modelvariant text) RETURNS integer
    LANGUAGE sql STABLE
    AS $_$
      SELECT dataset_id FROM dataset WHERE dataset_pers         = pers_email2id($1)
                                       AND dataset_name         = $2
                                       AND dataset_version      = $3
                                       AND dataset_guivariant   = $4
                                       AND dataset_modelvariant = $5
    $_$;


ALTER FUNCTION public.dataset_name2id(username text, name text, version text, guivariant text, modelvariant text) OWNER TO agrammon;

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

SET default_table_access_method = heap;

--
-- Name: data; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.data (
    data_id integer NOT NULL,
    data_dataset integer NOT NULL,
    data_var text NOT NULL,
    data_val text,
    data_comment text,
    data_instance_id integer
);


ALTER TABLE public.data OWNER TO agrammon;

--
-- Name: dataset; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.dataset (
    dataset_id integer NOT NULL,
    dataset_name text NOT NULL,
    dataset_pers integer NOT NULL,
    dataset_mod_date timestamp without time zone DEFAULT now(),
    dataset_version text DEFAULT '6.0'::text,
    dataset_comment text,
    dataset_model text DEFAULT 'Agrammon6'::text NOT NULL,
    dataset_readonly boolean DEFAULT false,
    dataset_guivariant text NOT NULL,
    dataset_modelvariant text NOT NULL,
    dataset_created timestamp without time zone DEFAULT now(),
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
    pers_role integer DEFAULT 1 NOT NULL,
    pers_old_password text
);


ALTER TABLE public.pers OWNER TO agrammon;

--
-- Name: all_data; Type: VIEW; Schema: public; Owner: agrammon
--

CREATE VIEW public.all_data AS
 SELECT pers.pers_email,
    dataset.dataset_name,
    data.data_var,
    data.data_val
   FROM ((public.pers
     JOIN public.dataset ON ((dataset.dataset_pers = pers.pers_id)))
     JOIN public.data ON ((data.data_dataset = dataset.dataset_id)))
  ORDER BY pers.pers_email, dataset.dataset_name, data.data_var;


ALTER VIEW public.all_data OWNER TO agrammon;

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


ALTER VIEW public.all_datasets OWNER TO agrammon;

--
-- Name: api_tokens; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.api_tokens (
    id integer NOT NULL,
    token text NOT NULL,
    expiration timestamp without time zone,
    metadata jsonb,
    revoked boolean
);


ALTER TABLE public.api_tokens OWNER TO agrammon;

--
-- Name: api_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.api_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_tokens_id_seq OWNER TO agrammon;

--
-- Name: api_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.api_tokens_id_seq OWNED BY public.api_tokens.id;


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


ALTER SEQUENCE public.branches_branches_id_seq OWNER TO agrammon;

--
-- Name: branches_branches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.branches_branches_id_seq OWNED BY public.branches.branches_id;


--
-- Name: data_data_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.data_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.data_data_id_seq OWNER TO agrammon;

--
-- Name: data_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.data_data_id_seq OWNED BY public.data.data_id;


--
-- Name: data_instance; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.data_instance (
    data_instance_id integer NOT NULL,
    data_instance_dataset integer NOT NULL,
    data_instance_name text NOT NULL,
    data_instance_order integer
);


ALTER TABLE public.data_instance OWNER TO agrammon;

--
-- Name: data_instance_data_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.data_instance_data_instance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.data_instance_data_instance_id_seq OWNER TO agrammon;

--
-- Name: data_instance_data_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.data_instance_data_instance_id_seq OWNED BY public.data_instance.data_instance_id;


--
-- Name: data_view; Type: VIEW; Schema: public; Owner: agrammon
--

CREATE VIEW public.data_view AS
 SELECT d.data_id,
    d.data_dataset,
    COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var) AS data_var,
    d.data_val,
    i.data_instance_order,
    d.data_comment
   FROM (public.data d
     LEFT JOIN public.data_instance i ON ((d.data_instance_id = i.data_instance_id)))
  ORDER BY d.data_dataset, COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var);


ALTER VIEW public.data_view OWNER TO agrammon;

--
-- Name: dataset_dataset_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.dataset_dataset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dataset_dataset_id_seq OWNER TO agrammon;

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


ALTER SEQUENCE public.news_news_id_seq OWNER TO agrammon;

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


ALTER SEQUENCE public.newsty_newsty_id_seq OWNER TO agrammon;

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


ALTER SEQUENCE public.pers_pers_id_seq OWNER TO agrammon;

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


ALTER SEQUENCE public.role_role_id_seq OWNER TO agrammon;

--
-- Name: role_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.role_role_id_seq OWNED BY public.role.role_id;


--
-- Name: session; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.session (
    session_id text NOT NULL,
    session_state text,
    session_expiration timestamp without time zone
);


ALTER TABLE public.session OWNER TO agrammon;

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


ALTER SEQUENCE public.tag_tag_id_seq OWNER TO agrammon;

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


ALTER SEQUENCE public.tagds_tagds_id_seq OWNER TO agrammon;

--
-- Name: tagds_tagds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.tagds_tagds_id_seq OWNED BY public.tagds.tagds_id;


--
-- Name: api_tokens id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.api_tokens ALTER COLUMN id SET DEFAULT nextval('public.api_tokens_id_seq'::regclass);


--
-- Name: branches branches_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.branches ALTER COLUMN branches_id SET DEFAULT nextval('public.branches_branches_id_seq'::regclass);


--
-- Name: data data_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data ALTER COLUMN data_id SET DEFAULT nextval('public.data_data_id_seq'::regclass);


--
-- Name: data_instance data_instance_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_instance ALTER COLUMN data_instance_id SET DEFAULT nextval('public.data_instance_data_instance_id_seq'::regclass);


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
-- Data for Name: api_tokens; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.api_tokens (id, token, expiration, metadata, revoked) FROM stdin;
\.


--
-- Data for Name: branches; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.branches (branches_id, branches_var, branches_data, branches_options) FROM stdin;
38869	85014781	{0,0,0,0,0,0,0,15.9,31.5,33.5,0,0,0,0,0,0,0,2.2,0,0,0,0,0,16.9}	{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}
38870	85014782	{0,0,0,0,0,0,0,15.9,31.5,33.5,0,0,0,0,0,0,0,2.2,0,0,0,0,0,16.9}	{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,once_a_day,no_manure_belt}
38871	85014767	{0,0,0,0,0,0,0,15.9,31.5,33.5,0,0,0,0,0,0,0,2.2,0,0,0,0,0,16.9}	{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}
38872	85014769	{0,0,0,0,0,0,0,15.9,31.5,33.5,0,0,0,0,0,0,0,2.2,0,0,0,0,0,16.9}	{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,once_a_day,no_manure_belt}
38877	85035421	{10,0,0,0,0,0,0,20,0,0,5,20,0,0,0,0,0,15,20,10}	{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}
38878	85035422	{10,0,0,0,0,0,0,20,0,0,5,20,0,0,0,0,0,15,20,10}	{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,no_manure_belt}
39179	85246055	{0,55,45,0,0,0,0,0,0,0}	{Slurry_Conventional,Slurry_Label,Slurry_Label_Open,Deep_Litter,Outdoor}
39180	85246060	{0,55,45,0,0,0,0,0,0,0}	{none,low_impuls_air_supply}
39181	85246071	{0,55,45,0,0,0,0,0,0,0}	{Slurry_Conventional,Slurry_Label,Slurry_Label_Open,Deep_Litter,Outdoor}
39182	85246078	{0,55,45,0,0,0,0,0,0,0}	{none,low_impuls_air_supply}
39216	85253539	{0,0,0,0,0,0,15.9,31.4,33.6,0,0,0,0,0,2.2,0,0,0,0,16.9}	{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}
39217	85253545	{0,0,0,0,0,0,15.9,31.4,33.6,0,0,0,0,0,2.2,0,0,0,0,16.9}	{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,no_manure_belt}
39218	85253530	{10,0,0,0,0,0,0,20,0,0,5,20,0,0,0,0,0,15,20,10}	{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}
39219	85253531	{10,0,0,0,0,0,0,20,0,0,5,20,0,0,0,0,0,15,20,10}	{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,no_manure_belt}
\.


--
-- Data for Name: data; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.data (data_id, data_dataset, data_var, data_val, data_comment, data_instance_id) FROM stdin;
82457616	61824	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	0	\N	\N
82457617	61824	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	0	\N	\N
82457618	61824	Application::Slurry::Ctech::share_splash_plate	0	\N	\N
82457619	61824	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
82457620	61824	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
82457621	61824	Application::SolidManure::Cseason::appl_summer	0	\N	\N
82457622	61824	PlantProduction::MineralFertiliser::soil_ph	unknown	\N	\N
82457623	61824	PlantProduction::RecyclingFertiliser::solid_digestate	0	\N	\N
82457624	61824	Storage::SolidManure::Poultry::share_covered_basin	0	\N	\N
82457625	61824	Application::Slurry::Ctech::share_trailing_hose	0	\N	\N
82457626	61824	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
82457627	61824	Application::Slurry::Applrate::dilution_parts_water	2	\N	\N
82457628	61824	Application::Slurry::Applrate::appl_rate	10	\N	\N
82457629	61824	Application::Slurry::Csoft::appl_hotdays	frequently	\N	\N
82457630	61824	Application::Slurry::Cseason::appl_summer	0	\N	\N
82457631	61824	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
82457632	61824	Application::SolidManure::CincorpTime::incorp_gt3d	0	\N	\N
82457633	61824	Application::SolidManure::Cseason::appl_autumn_winter_spring	0	\N	\N
82457634	61824	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
82457635	61824	Storage::SolidManure::Solid::share_applied_direct_pig_manure	0	\N	\N
82457636	61824	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
82457637	61824	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
82457638	61824	Application::Slurry::Cseason::appl_autumn_winter_spring	0	\N	\N
82457639	61824	Application::SolidManure::CincorpTime::incorp_lw4h	0	\N	\N
82457640	61824	Application::SolidManure::CincorpTime::incorp_lw8h	0	\N	\N
82457641	61824	Application::SolidManure::CincorpTime::incorp_lw3d	0	\N	\N
82457642	61824	PlantProduction::RecyclingFertiliser::compost	1	\N	\N
82457643	61824	PlantProduction::RecyclingFertiliser::liquid_digestate	0	\N	\N
82457644	61824	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
82457645	61824	Application::Slurry::Csoft::appl_evening	0	\N	\N
82457646	61824	Application::SolidManure::CincorpTime::incorp_none	0	\N	\N
82475514	61996	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
82475515	61996	Application::SolidManure::CincorpTime::incorp_lw3d	0	\N	\N
82475516	61996	Application::SolidManure::CincorpTime::incorp_gt3d	0	\N	\N
82475517	61996	Application::SolidManure::CincorpTime::incorp_none	100	\N	\N
82475518	61996	Application::Slurry::Ctech::share_splash_plate	0	\N	\N
82475544	61996	PlantProduction::RecyclingFertiliser::liquid_digestate	0	\N	\N
82475624	61996	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	0	\N	\N
82475625	61996	Storage::SolidManure::Poultry::share_covered_basin	0	\N	\N
82475626	61996	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	0	\N	\N
82475627	61996	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
82475628	61996	Storage::SolidManure::Solid::share_applied_direct_pig_manure	0	\N	\N
82475629	61996	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
82475637	61996	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
82475638	61996	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
82475639	61996	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
82475640	61996	Application::Slurry::Applrate::dilution_parts_water	1	\N	\N
82475641	61996	Application::Slurry::Applrate::appl_rate	30	\N	\N
82475642	61996	Application::Slurry::Csoft::appl_evening	0	\N	\N
82475643	61996	Application::Slurry::Csoft::appl_hotdays	sometimes	\N	\N
82475644	61996	Application::Slurry::Cseason::appl_summer	47	\N	\N
82475645	61996	Application::Slurry::Cseason::appl_autumn_winter_spring	53	\N	\N
82475646	61996	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
82475647	61996	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
82475648	61996	Application::Slurry::Ctech::share_trailing_hose	100	\N	\N
82475649	61996	Application::SolidManure::CincorpTime::incorp_lw4h	0	\N	\N
82475650	61996	Application::SolidManure::CincorpTime::incorp_lw8h	0	\N	\N
82475651	61996	Application::SolidManure::Cseason::appl_summer	30	\N	\N
82475652	61996	Application::SolidManure::Cseason::appl_autumn_winter_spring	70	\N	\N
82475653	61996	PlantProduction::MineralFertiliser::mineral_fertiliser_ammoniumNitrate_amount	1481.5	\N	\N
82475654	61996	PlantProduction::MineralFertiliser::mineral_fertiliser_urea_amount	0.0	\N	\N
82475655	61996	PlantProduction::RecyclingFertiliser::compost	0	\N	\N
82475656	61996	PlantProduction::RecyclingFertiliser::solid_digestate	0	\N	\N
82475669	61996	Application::Slurry::CfreeFactor::free_correction_factor	0	\N	\N
83129154	67813	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
83129155	67813	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
83129156	67813	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
83129162	67813	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	0	\N	\N
83129163	67813	Storage::SolidManure::Poultry::share_covered_basin	0	\N	\N
83129164	67813	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	0	\N	\N
83129165	67813	Storage::SolidManure::Solid::share_applied_direct_pig_manure	0	\N	\N
83129169	67813	Application::Slurry::Ctech::share_splash_plate	100	\N	\N
83129170	67813	Application::Slurry::Ctech::share_trailing_hose	0	\N	\N
83129171	67813	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
83129172	67813	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
83129173	67813	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
83129174	67813	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
83129175	67813	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
83129176	67813	Application::SolidManure::CincorpTime::incorp_lw3d	100	\N	\N
83129177	67813	Application::SolidManure::CincorpTime::incorp_none	0	\N	\N
83129178	67813	PlantProduction::RecyclingFertiliser::compost	5	\N	\N
83129179	67813	PlantProduction::RecyclingFertiliser::solid_digestate	5	\N	\N
83129180	67813	PlantProduction::RecyclingFertiliser::liquid_digestate	5	\N	\N
83129200	67813	Application::SolidManure::CfreeFactor::free_correction_factor	0	\N	\N
85014885	77117	Storage::SolidManure::Poultry::share_covered_basin	10	\N	\N
85014898	77117	Application::Slurry::Cseason::appl_autumn_winter_spring	50	\N	\N
85014899	77117	Application::Slurry::Cseason::appl_summer	50	\N	\N
85014900	77117	Application::SolidManure::CincorpTime::incorp_lw4h	100	\N	\N
85014901	77117	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
85014902	77117	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
85014903	77117	Application::SolidManure::CincorpTime::incorp_lw3d	0	\N	\N
85014904	77117	Application::SolidManure::CincorpTime::incorp_lw8h	0	\N	\N
85014905	77117	Application::SolidManure::CincorpTime::incorp_gt3d	0	\N	\N
85014906	77117	Application::SolidManure::CincorpTime::incorp_none	0	\N	\N
85014907	77117	Application::SolidManure::Cseason::appl_autumn_winter_spring	40	\N	\N
85014908	77117	Application::SolidManure::Cseason::appl_summer	60	\N	\N
85014909	77117	PlantProduction::RecyclingFertiliser::solid_digestate	0	\N	\N
85014910	77117	PlantProduction::RecyclingFertiliser::liquid_digestate	1	\N	\N
85014911	77117	PlantProduction::RecyclingFertiliser::compost	0	\N	\N
85014912	77117	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
85014913	77117	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
85014736	77115	Storage::SolidManure::Poultry::share_covered_basin	10	\N	\N
85014737	77115	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	10	\N	\N
85014738	77115	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	10	\N	\N
85014739	77115	Storage::SolidManure::Solid::share_applied_direct_pig_manure	10	\N	\N
85014740	77115	Application::Slurry::Ctech::share_splash_plate	100	\N	\N
85014741	77115	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
85014742	77115	Application::Slurry::Ctech::share_trailing_hose	0	\N	\N
85014743	77115	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
85014744	77115	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
85014745	77115	Application::Slurry::Applrate::appl_rate	10	\N	\N
85014746	77115	Application::Slurry::Applrate::dilution_parts_water	2	\N	\N
85014747	77115	Application::Slurry::Csoft::appl_hotdays	sometimes	\N	\N
85014748	77115	Application::Slurry::Csoft::appl_evening	20	\N	\N
85014749	77115	Application::Slurry::Cseason::appl_autumn_winter_spring	50	\N	\N
85014750	77115	Application::Slurry::Cseason::appl_summer	50	\N	\N
85014751	77115	Application::SolidManure::CincorpTime::incorp_lw4h	100	\N	\N
85014752	77115	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
85014753	77115	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
85014754	77115	Application::SolidManure::CincorpTime::incorp_lw3d	0	\N	\N
85014755	77115	Application::SolidManure::CincorpTime::incorp_lw8h	0	\N	\N
85014756	77115	Application::SolidManure::CincorpTime::incorp_gt3d	0	\N	\N
85014757	77115	Application::SolidManure::CincorpTime::incorp_none	0	\N	\N
85014758	77115	Application::SolidManure::Cseason::appl_autumn_winter_spring	40	\N	\N
85014759	77115	Application::SolidManure::Cseason::appl_summer	60	\N	\N
85014760	77115	PlantProduction::RecyclingFertiliser::solid_digestate	0	\N	\N
85014761	77115	PlantProduction::RecyclingFertiliser::liquid_digestate	1	\N	\N
85014762	77115	PlantProduction::RecyclingFertiliser::compost	0	\N	\N
85014763	77115	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
85014764	77115	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
85014765	77115	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
85014774	77115	PlantProduction::MineralFertiliser::soil_ph	high	\N	\N
85014886	77117	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	10	\N	\N
85014887	77117	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	10	\N	\N
85014888	77117	Storage::SolidManure::Solid::share_applied_direct_pig_manure	10	\N	\N
85014889	77117	Application::Slurry::Ctech::share_splash_plate	100	\N	\N
85014890	77117	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
85014891	77117	Application::Slurry::Ctech::share_trailing_hose	0	\N	\N
85014892	77117	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
85014893	77117	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
85014894	77117	Application::Slurry::Applrate::appl_rate	10	\N	\N
85014895	77117	Application::Slurry::Applrate::dilution_parts_water	2	\N	\N
85014896	77117	Application::Slurry::Csoft::appl_hotdays	sometimes	\N	\N
85014897	77117	Application::Slurry::Csoft::appl_evening	20	\N	\N
85014914	77117	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
85014915	77117	PlantProduction::MineralFertiliser::soil_ph	high	\N	\N
85035382	77153	Storage::SolidManure::Poultry::share_covered_basin	10	\N	\N
85035383	77153	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	10	\N	\N
85035384	77153	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	10	\N	\N
85035385	77153	Storage::SolidManure::Solid::share_applied_direct_pig_manure	10	\N	\N
85035386	77153	Application::Slurry::Ctech::share_splash_plate	100	\N	\N
85035387	77153	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
85035388	77153	Application::Slurry::Ctech::share_trailing_hose	0	\N	\N
85035389	77153	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
85035390	77153	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
85035391	77153	Application::Slurry::Applrate::appl_rate	10	\N	\N
85035392	77153	Application::Slurry::Applrate::dilution_parts_water	2	\N	\N
85035393	77153	Application::Slurry::Csoft::appl_hotdays	sometimes	\N	\N
85035394	77153	Application::Slurry::Csoft::appl_evening	20	\N	\N
85035395	77153	Application::Slurry::Cseason::appl_autumn_winter_spring	50	\N	\N
85035396	77153	Application::Slurry::Cseason::appl_summer	50	\N	\N
85035397	77153	Application::SolidManure::CincorpTime::incorp_lw4h	100	\N	\N
85035398	77153	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
85035399	77153	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
85035400	77153	Application::SolidManure::CincorpTime::incorp_lw3d	0	\N	\N
85035401	77153	Application::SolidManure::CincorpTime::incorp_lw8h	0	\N	\N
85035402	77153	Application::SolidManure::CincorpTime::incorp_gt3d	0	\N	\N
85035403	77153	Application::SolidManure::CincorpTime::incorp_none	0	\N	\N
85035404	77153	Application::SolidManure::Cseason::appl_autumn_winter_spring	40	\N	\N
85035405	77153	Application::SolidManure::Cseason::appl_summer	60	\N	\N
85035406	77153	PlantProduction::RecyclingFertiliser::solid_digestate	0	\N	\N
85035407	77153	PlantProduction::RecyclingFertiliser::liquid_digestate	1	\N	\N
85035408	77153	PlantProduction::RecyclingFertiliser::compost	0	\N	\N
85035409	77153	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
85035410	77153	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
85035411	77153	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
85035413	77153	PlantProduction::MineralFertiliser::soil_ph	high	\N	\N
85245953	77615	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	0	\N	\N
85245954	77615	Storage::SolidManure::Poultry::share_covered_basin	0	\N	\N
85245955	77615	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	0	\N	\N
85245956	77615	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
85245957	77615	Storage::SolidManure::Solid::share_applied_direct_pig_manure	0	\N	\N
85245958	77615	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
85245976	77615	Application::Slurry::Ctech::share_splash_plate	100	\N	\N
85245977	77615	Application::Slurry::Ctech::share_trailing_hose	0	\N	\N
85245978	77615	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
85245979	77615	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
85245980	77615	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
85245981	77615	Application::Slurry::Applrate::dilution_parts_water	1	\N	\N
85245982	77615	Application::Slurry::Applrate::appl_rate	30	\N	\N
85245983	77615	Application::Slurry::Csoft::appl_evening	0	\N	\N
85245984	77615	Application::Slurry::Csoft::appl_hotdays	sometimes	\N	\N
85245985	77615	Application::Slurry::Cseason::appl_summer	50	\N	\N
85245986	77615	Application::Slurry::Cseason::appl_autumn_winter_spring	50	\N	\N
85245987	77615	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
85245988	77615	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
85245989	77615	Application::SolidManure::CincorpTime::incorp_lw4h	0	\N	\N
85245990	77615	Application::SolidManure::CincorpTime::incorp_lw8h	0	\N	\N
85245991	77615	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
85245992	77615	Application::SolidManure::CincorpTime::incorp_lw3d	0	\N	\N
85245993	77615	Application::SolidManure::CincorpTime::incorp_gt3d	0	\N	\N
85245994	77615	Application::SolidManure::CincorpTime::incorp_none	100	\N	\N
85245995	77615	Application::SolidManure::Cseason::appl_summer	50	\N	\N
85245996	77615	Application::SolidManure::Cseason::appl_autumn_winter_spring	50	\N	\N
85245959	77615	Storage::Slurry[]::volume	2000	\N	9
85245997	77615	PlantProduction::MineralFertiliser::soil_ph	unknown	\N	\N
85245998	77615	PlantProduction::RecyclingFertiliser::compost	0	\N	\N
85245999	77615	PlantProduction::RecyclingFertiliser::solid_digestate	0	\N	\N
85246000	77615	PlantProduction::RecyclingFertiliser::liquid_digestate	0	\N	\N
85246066	77615	PlantProduction::MineralFertiliser::mineral_fertiliser_ammoniumNitrate_amount	1000.0	\N	\N
85246067	77615	PlantProduction::MineralFertiliser::mineral_fertiliser_urea_amount	1000.0	\N	\N
85253434	77651	PlantProduction::MineralFertiliser::soil_ph	high	\N	\N
85253436	77651	Application::SolidManure::CincorpTime::incorp_lw4h	100	\N	\N
85253437	77651	Application::SolidManure::CincorpTime::incorp_lw1d	0	\N	\N
85253438	77651	Application::SolidManure::CincorpTime::incorp_lw1h	0	\N	\N
85253446	77651	Application::Slurry::Csoft::appl_hotdays	sometimes	\N	\N
85253447	77651	Application::Slurry::Csoft::appl_evening	20	\N	\N
85253448	77651	Application::Slurry::Cseason::appl_autumn_winter_spring	50	\N	\N
85253449	77651	Application::Slurry::Cseason::appl_summer	50	\N	\N
85253450	77651	Storage::SolidManure::Poultry::share_covered_basin	10	\N	\N
85253451	77651	Storage::SolidManure::Poultry::share_applied_direct_poultry_manure	10	\N	\N
85253452	77651	Storage::SolidManure::Solid::share_applied_direct_cattle_other_manure	10	\N	\N
85253461	77651	Storage::SolidManure::Solid::share_applied_direct_pig_manure	10	\N	\N
85253462	77651	Application::Slurry::Ctech::share_splash_plate	100	\N	\N
85253463	77651	Application::Slurry::Ctech::share_trailing_shoe	0	\N	\N
85253464	77651	Application::Slurry::Ctech::share_trailing_hose	0	\N	\N
85253465	77651	Application::Slurry::Ctech::share_shallow_injection	0	\N	\N
85253466	77651	Application::Slurry::Ctech::share_deep_injection	0	\N	\N
85253467	77651	Application::Slurry::Applrate::appl_rate	10	\N	\N
85253468	77651	Application::Slurry::Applrate::dilution_parts_water	2	\N	\N
85253469	77651	Application::SolidManure::CincorpTime::incorp_lw3d	0	\N	\N
85253470	77651	Application::SolidManure::CincorpTime::incorp_lw8h	0	\N	\N
85253471	77651	Application::SolidManure::CincorpTime::incorp_gt3d	0	\N	\N
85253472	77651	Application::SolidManure::CincorpTime::incorp_none	0	\N	\N
85253473	77651	Application::SolidManure::Cseason::appl_autumn_winter_spring	40	\N	\N
85253474	77651	Application::SolidManure::Cseason::appl_summer	60	\N	\N
85253475	77651	PlantProduction::RecyclingFertiliser::solid_digestate	0	\N	\N
85253476	77651	PlantProduction::RecyclingFertiliser::liquid_digestate	1	\N	\N
85253477	77651	PlantProduction::RecyclingFertiliser::compost	0	\N	\N
85253478	77651	Application::Slurry::Cfermented::fermented_slurry	0	\N	\N
85253479	77651	Storage::SolidManure::Solid::share_covered_basin_pig_manure	0	\N	\N
85253481	77651	Storage::SolidManure::Solid::share_covered_basin_cattle_manure	0	\N	\N
85253457	77651	Livestock::DairyCow[]::Excretion::dimensioning_barn	1000	\N	27
85253456	77651	Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor	none	\N	27
85245951	77615	Livestock::DairyCow[]::Outdoor::grazing_days	200	\N	23
85253491	77651	Livestock::DairyCow[]::Outdoor::grazing_days	100	\N	27
85014948	77117	Livestock::DairyCow[]::Outdoor::grazing_hours	10	\N	29
85245952	77615	Livestock::DairyCow[]::Outdoor::grazing_hours	12	\N	23
85253492	77651	Livestock::DairyCow[]::Outdoor::grazing_hours	10	\N	27
85014929	77117	Livestock::DairyCow[]::Outdoor::yard_days	100	\N	29
85245942	77615	Livestock::DairyCow[]::Outdoor::yard_days	100	\N	23
82475541	61996	Livestock::DairyCow[]::Outdoor::exercise_yard	available_roughage_is_not_supplied_in_the_exercise_yard	\N	12
85014939	77117	Livestock::DairyCow[]::Outdoor::exercise_yard	available_roughage_is_not_supplied_in_the_exercise_yard	\N	29
85245943	77615	Livestock::DairyCow[]::Outdoor::exercise_yard	flattened	\N	23
85253455	77651	Livestock::DairyCow[]::Outdoor::exercise_yard	available_roughage_is_not_supplied_in_the_exercise_yard	\N	27
82475545	61996	Livestock::DairyCow[]::Outdoor::free_correction_factor	0	\N	12
85014936	77117	Livestock::DairyCow[]::Outdoor::free_correction_factor	0	\N	29
85245950	77615	Livestock::DairyCow[]::Outdoor::free_correction_factor	0	\N	23
85253435	77651	Livestock::DairyCow[]::Outdoor::free_correction_factor	-20	\N	27
82475597	61996	Livestock::OtherCattle[]::Outdoor::yard_days	155	\N	24
82475615	61996	Livestock::OtherCattle[]::Outdoor::yard_days	160	\N	26
82475589	61996	Livestock::OtherCattle[]::Outdoor::exercise_yard	available_roughage_is_not_supplied_in_the_exercise_yard	\N	19
82475600	61996	Livestock::OtherCattle[]::Outdoor::exercise_yard	available_roughage_is_not_supplied_in_the_exercise_yard	\N	24
82475618	61996	Livestock::OtherCattle[]::Outdoor::exercise_yard	available_roughage_is_not_supplied_in_the_exercise_yard	\N	26
82475579	61996	Livestock::OtherCattle[]::Outdoor::free_correction_factor	0	\N	19
82475606	61996	Livestock::OtherCattle[]::Outdoor::free_correction_factor	0	\N	24
82475619	61996	Livestock::OtherCattle[]::Outdoor::free_correction_factor	0	\N	26
85714050	67813	Livestock::Pig[]::Excretion::dimensioning_barn	20	\N	30
85714051	67813	Livestock::Pig[]::Housing::Type::housing_type	Slurry_Label	\N	30
85714053	67813	Livestock::FatteningPigs[]::Excretion::dimensioning_barn	20	\N	14
85714054	67813	Livestock::FatteningPigs[]::Housing::Type::housing_type	Slurry_Label	\N	14
85714055	67813	Livestock::Poultry[]::Excretion::dimensioning_barn	50	\N	33
82475496	61996	Livestock::Pig[]::Housing::Type::housing_type	Slurry_Label_Open	\N	22
82475497	61996	Livestock::Poultry[]::Excretion::animals	100	\N	22
82475498	61996	Livestock::Poultry[]::Housing::Type::manure_removal_interval	once_a_day	\N	22
82475501	61996	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	22
82475502	61996	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	22
82475504	61996	Livestock::Poultry[]::Housing::Type::housing_type	manure_belt_with_manure_belt_drying_system	\N	22
82475505	61996	Livestock::Poultry[]::Housing::Type::drinking_system	bell_drinkers	\N	22
82475506	61996	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	22
82475511	61996	Livestock::FatteningPigs[]::Housing::CFreeFactor::free_correction_factor	0	\N	22
82475519	61996	Livestock::DairyCow[]::Excretion::CMilk::milk_yield	6800	\N	12
82475520	61996	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_hay_summer	0	\N	12
82475521	61996	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_silage_summer	0	\N	12
82475522	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_grass_silage_winter	0	\N	12
82475523	61996	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_pellets_summer	0	\N	12
82475525	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_silage_winter	0	\N	12
82475526	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_pellets_winter	0	\N	12
82475527	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_potatoes_winter	0	\N	12
82475528	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_beets_winter	0	\N	12
82475529	61996	Livestock::DairyCow[]::Excretion::CConcentrates::amount_summer	1	\N	12
82475530	61996	Livestock::DairyCow[]::Excretion::CConcentrates::amount_winter	2	\N	12
82475531	61996	Livestock::DairyCow[]::Housing::Type::housing_type	Tied_Housing_Slurry_Plus_Solid_Manure	\N	12
82475535	61996	Livestock::DairyCow[]::Housing::CFreeFactor::free_correction_factor	0	\N	12
82475547	61996	Livestock::DairyCow[]::Excretion::CMilk::milk_yield	6800	\N	11
82475548	61996	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_silage_summer	0	\N	11
82475549	61996	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_hay_summer	0	\N	11
82475532	61996	Livestock::DairyCow[]::Excretion::dimensioning_barn	30	\N	12
82475537	61996	Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor	none	\N	12
82475543	61996	Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	12
82475542	61996	Livestock::DairyCow[]::Outdoor::grazing_days	190	\N	12
82475546	61996	Livestock::DairyCow[]::Outdoor::grazing_hours	8.5	\N	12
82475539	61996	Livestock::DairyCow[]::Outdoor::yard_days	175	\N	12
82475503	61996	Livestock::Poultry[]::Grazing::free_range	yes	\N	22
82475551	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_silage_winter	0	\N	11
82475552	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_grass_silage_winter	0	\N	11
82475553	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_potatoes_winter	0	\N	11
82475554	61996	Livestock::DairyCow[]::Excretion::CConcentrates::amount_summer	1	\N	11
82475555	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_beets_winter	0	\N	11
82475556	61996	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_pellets_winter	0	\N	11
82475557	61996	Livestock::DairyCow[]::Excretion::CConcentrates::amount_winter	2	\N	11
82475561	61996	Livestock::DairyCow[]::Housing::CFreeFactor::free_correction_factor	0	\N	11
82475567	61996	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_pellets_summer	0	\N	11
82475572	61996	Livestock::DairyCow[]::Housing::Type::housing_type	Tied_Housing_Slurry_Plus_Solid_Manure	\N	11
82475575	61996	Livestock::OtherCattle[]::Excretion::animals	8	\N	19
82475585	61996	Livestock::OtherCattle[]::Housing::CFreeFactor::free_correction_factor	0	\N	19
82475586	61996	Livestock::OtherCattle[]::Excretion::animalcategory	heifers_1st_yr	\N	19
82475512	61996	Livestock::FatteningPigs[]::Excretion::feeding_phase_2_crude_protein	135	\N	22
82475508	61996	Livestock::FatteningPigs[]::Excretion::feeding_phase_3_crude_protein	135	\N	22
82475510	61996	Livestock::FatteningPigs[]::Excretion::energy_content	15	\N	22
83129240	67813	Livestock::DairyCow[]::Housing::Type::Loose_Housing_Deep_Litter::ignore	ignore	\N	8
82475587	61996	Livestock::OtherCattle[]::Housing::Type::housing_type	Loose_Housing_Deep_Litter	\N	19
82475591	61996	Livestock::OtherCattle[]::Excretion::animals	6	\N	24
82475595	61996	Livestock::OtherCattle[]::Housing::CFreeFactor::free_correction_factor	0	\N	24
82475558	61996	Livestock::DairyCow[]::Excretion::dimensioning_barn	30	\N	11
82475570	61996	Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor	none	\N	11
82475573	61996	Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	11
82475564	61996	Livestock::DairyCow[]::Outdoor::grazing_days	190	\N	11
82475566	61996	Livestock::DairyCow[]::Outdoor::grazing_hours	8.5	\N	11
82475562	61996	Livestock::DairyCow[]::Outdoor::yard_days	175	\N	11
82475571	61996	Livestock::DairyCow[]::Outdoor::exercise_yard	available_roughage_is_not_supplied_in_the_exercise_yard	\N	11
82475565	61996	Livestock::DairyCow[]::Outdoor::free_correction_factor	0	\N	11
82475583	61996	Livestock::OtherCattle[]::Excretion::dimensioning_barn	8	\N	19
82475593	61996	Livestock::OtherCattle[]::Excretion::dimensioning_barn	6	\N	24
82475588	61996	Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor	none	\N	19
82475592	61996	Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor	none	\N	24
82475590	61996	Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	19
82475598	61996	Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	24
82475584	61996	Livestock::OtherCattle[]::Outdoor::grazing_days	190	\N	19
82475601	61996	Livestock::OtherCattle[]::Outdoor::grazing_days	210	\N	24
82475582	61996	Livestock::OtherCattle[]::Outdoor::grazing_hours	12	\N	19
82475602	61996	Livestock::OtherCattle[]::Outdoor::grazing_hours	24	\N	24
82475581	61996	Livestock::OtherCattle[]::Outdoor::yard_days	165	\N	19
82475605	61996	Livestock::OtherCattle[]::Excretion::animalcategory	heifers_2nd_yr	\N	24
82475607	61996	Livestock::OtherCattle[]::Excretion::animalcategory	heifers_3rd_yr	\N	26
82475608	61996	Livestock::OtherCattle[]::Housing::Type::housing_type	Loose_Housing_Slurry_Plus_Solid_Manure	\N	26
82475609	61996	Livestock::OtherCattle[]::Excretion::animals	6	\N	26
82475611	61996	Livestock::OtherCattle[]::Housing::CFreeFactor::free_correction_factor	0	\N	26
82475630	61996	Storage::Slurry[]::volume	550	\N	15
82475631	61996	Storage::Slurry[]::depth	2.8	\N	15
82475632	61996	Storage::Slurry[]::EFLiquid::free_correction_factor	0	\N	15
82475633	61996	Storage::Slurry[]::mixing_frequency	7_to_12_times_per_year	\N	15
82475634	61996	Storage::Slurry[]::EFLiquid::cover_type	solid_cover	\N	15
82475635	61996	Storage::Slurry[]::EFLiquid::contains_cattle_manure	yes	\N	15
82475636	61996	Storage::Slurry[]::EFLiquid::contains_pig_manure	no	\N	15
82475657	61996	Livestock::OtherCattle[]::Housing::Type::housing_type	Loose_Housing_Slurry_Plus_Solid_Manure	\N	24
82475660	61996	Livestock::Pig[]::Housing::CFreeFactor::free_correction_factor	10	\N	22
82475661	61996	Livestock::Pig[]::Excretion::crude_protein	165	\N	22
82475665	61996	Livestock::Pig[]::Excretion::animalcategory	nursing_sows	\N	22
82475667	61996	Livestock::Pig[]::Excretion::energy_content	12	\N	22
82475668	61996	Livestock::Pig[]::Housing::AirScrubber::air_scrubber	none	\N	22
82475610	61996	Livestock::OtherCattle[]::Excretion::dimensioning_barn	6	\N	26
82475623	61996	Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor	none	\N	26
82475616	61996	Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	26
82475620	61996	Livestock::OtherCattle[]::Outdoor::grazing_days	205	\N	26
82475621	61996	Livestock::OtherCattle[]::Outdoor::grazing_hours	24	\N	26
82475658	61996	Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor	none	\N	22
82475664	61996	Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_air	none	\N	22
83129158	67813	Livestock::DairyCow[]::Outdoor::exercise_yard	not_available	\N	8
83129157	67813	Livestock::DairyCow[]::Housing::Type::housing_type	Tied_Housing_Slurry	\N	8
83129160	67813	Storage::Slurry[]::volume	100	\N	21
83129161	67813	Storage::Slurry[]::depth	2	\N	21
83129181	67813	Livestock::DairyCow[]::Outdoor::grazing_days	200	\N	17
83129182	67813	Livestock::DairyCow[]::Outdoor::grazing_hours	10	\N	17
83129166	67813	Storage::Slurry[]::EFLiquid::cover_type	solid_cover	\N	21
83129167	67813	Storage::Slurry[]::EFLiquid::contains_cattle_manure	yes	\N	21
83129168	67813	Storage::Slurry[]::EFLiquid::contains_pig_manure	yes	\N	21
83129203	67813	Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor	none	\N	20
83129219	67813	Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	20
83129206	67813	Livestock::OtherCattle[]::Outdoor::grazing_hours	8	\N	20
83129205	67813	Livestock::OtherCattle[]::Outdoor::exercise_yard	not_available	\N	20
83129201	67813	Livestock::OtherCattle[]::Housing::CFreeFactor::free_correction_factor	0	\N	20
83129207	67813	Livestock::DairyCow[]::Excretion::CMilk::milk_yield	7000	\N	17
83129221	67813	Livestock::DairyCow[]::Housing::Type::housing_type	Tied_Housing_Slurry	\N	17
83129228	67813	Livestock::DairyCow[]::Housing::CFreeFactor::free_correction_factor	0	\N	17
83129236	67813	Livestock::DairyCow[]::Housing::KGrazing::ignore	ignore	\N	8
83129239	67813	Livestock::DairyCow[]::Housing::ignore	ignore	\N	8
83129241	67813	Livestock::DairyCow[]::Housing::Type::Loose_Housing_Slurry_Plus_Solid_Manure::ignore	ignore	\N	8
83129242	67813	Livestock::DairyCow[]::Housing::Type::Loose_Housing_Slurry::ignore	ignore	\N	8
83129243	67813	Livestock::DairyCow[]::Housing::Type::Tied_Housing_Slurry_Plus_Solid_Manure::ignore	ignore	\N	8
83129244	67813	Livestock::DairyCow[]::Housing::Type::Tied_Housing_Slurry::ignore	ignore	\N	8
83129258	67813	Livestock::DairyCow[]::ignore	ignore	\N	8
83129259	67813	Livestock::DairyCow[]::Excretion::CMilk::milk_yield	7000	\N	8
83129260	67813	Livestock::DairyCow[]::Excretion::CFeed::ignore	ignore	\N	8
83129222	67813	Livestock::DairyCow[]::Excretion::dimensioning_barn	100	\N	17
83129245	67813	Livestock::DairyCow[]::Excretion::dimensioning_barn	100	\N	8
83129225	67813	Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor	none	\N	17
83129232	67813	Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard	perforated_floor	\N	17
83129261	67813	Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard	perforated_floor	\N	8
83129235	67813	Livestock::DairyCow[]::Outdoor::grazing_days	200	\N	8
83129234	67813	Livestock::DairyCow[]::Outdoor::grazing_hours	10	\N	8
83129229	67813	Livestock::DairyCow[]::Outdoor::yard_days	100	\N	17
83129237	67813	Livestock::DairyCow[]::Outdoor::yard_days	100	\N	8
83129230	67813	Livestock::DairyCow[]::Outdoor::exercise_yard	not_available	\N	17
83129247	67813	Livestock::OtherCattle[]::Excretion::dimensioning_barn	10	\N	20
83129248	67813	Livestock::OtherCattle[]::Outdoor::grazing_days	200	\N	20
83129270	67813	Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor	none	\N	8
83129269	67813	Livestock::OtherCattle[]::Outdoor::yard_days	200	\N	20
83129283	67813	Livestock::SmallRuminants[]::Housing::CFreeFactor::free_correction_factor	0	\N	25
83129279	67813	Livestock::Poultry[]::Grazing::free_range	yes	\N	33
83129264	67813	Livestock::OtherCattle[]::Excretion::animalcategory	suckling_cows	\N	20
83129265	67813	Livestock::OtherCattle[]::Excretion::animals	10	\N	20
83129266	67813	Livestock::OtherCattle[]::Housing::Type::housing_type	Tied_Housing_Slurry	\N	20
83129274	67813	Livestock::Pig[]::Excretion::crude_protein	150	\N	30
83129277	67813	Livestock::FatteningPigs[]::Excretion::feeding_phase_1_crude_protein	150	\N	14
83129278	67813	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	33
83129280	67813	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	33
83129281	67813	Livestock::Equides[]::Excretion::animals	10	\N	7
83129285	67813	Livestock::Pig[]::Housing::CFreeFactor::free_correction_factor	0	\N	30
83129288	67813	Livestock::Pig[]::Housing::AirScrubber::air_scrubber	none	\N	30
83129290	67813	Livestock::FatteningPigs[]::Excretion::feeding_phase_2_crude_protein	150	\N	14
83129291	67813	Livestock::Pig[]::Excretion::energy_content	15	\N	30
83129301	67813	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor	none	\N	14
83129292	67813	Livestock::FatteningPigs[]::Housing::CFreeFactor::free_correction_factor	0	\N	14
83129297	67813	Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor	none	\N	30
83129294	67813	Livestock::FatteningPigs[]::Excretion::energy_content	15	\N	14
83129320	67813	Livestock::Equides[]::Housing::CFreeFactor::free_correction_factor	0	\N	7
83129296	67813	Livestock::Pig[]::Excretion::animalcategory	nursing_sows	\N	30
83129307	67813	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air	none	\N	14
83129299	67813	Livestock::FatteningPigs[]::Excretion::feeding_phase_3_crude_protein	150	\N	14
83129305	67813	Livestock::SmallRuminants[]::Grazing::grazing_hours	23.9	\N	25
83129308	67813	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	33
83129309	67813	Livestock::Poultry[]::Housing::Type::housing_type	manure_belt_with_manure_belt_drying_system	\N	33
83129311	67813	Livestock::Equides[]::Excretion::animalcategory	horses_older_than_3yr	\N	7
83129313	67813	Livestock::SmallRuminants[]::Grazing::grazing_days	365	\N	25
83129315	67813	Livestock::FatteningPigs[]::Housing::AirScrubber::air_scrubber	none	\N	14
83129317	67813	Livestock::Poultry[]::Excretion::animals	50	\N	33
83129318	67813	Livestock::Poultry[]::Housing::Type::manure_removal_interval	less_than_twice_a_month	\N	33
83129319	67813	Livestock::Poultry[]::Housing::Type::drinking_system	drinking_nipples	\N	33
83129322	67813	Livestock::SmallRuminants[]::Excretion::animalcategory	fattening_sheep	\N	25
83129323	67813	Livestock::SmallRuminants[]::Excretion::animals	20	\N	25
83129302	67813	Livestock::Equides[]::Outdoor::grazing_days	200	\N	7
83129303	67813	Livestock::Equides[]::Outdoor::yard_days	200	\N	7
83129304	67813	Livestock::Equides[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	7
85014883	77117	Storage::Slurry[]::depth	2	\N	5
85014884	77117	Storage::Slurry[]::volume	1000	\N	5
85014729	77115	Storage::Slurry[]::EFLiquid::contains_pig_manure	no	\N	6
85014730	77115	Storage::Slurry[]::EFLiquid::contains_cattle_manure	yes	\N	6
85014731	77115	Storage::Slurry[]::EFLiquid::cover_type	uncovered	\N	6
85014732	77115	Storage::Slurry[]::mixing_frequency	at_most_2_times_per_year	\N	6
85014733	77115	Storage::Slurry[]::EFLiquid::free_correction_factor	0	\N	6
85014734	77115	Storage::Slurry[]::depth	2	\N	6
85014735	77115	Storage::Slurry[]::volume	1000	\N	6
85014766	77115	Livestock::Poultry[]::Excretion::animals	1000	\N	34
85014767	77115	Livestock::Poultry[]::Housing::Type::housing_type	branched	\N	34
85014768	77115	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	34
85014769	77115	Livestock::Poultry[]::Housing::Type::manure_removal_interval	branched	\N	34
85014770	77115	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	34
85014772	77115	Livestock::Poultry[]::Housing::Type::drinking_system	drinking_nipples	\N	34
85014773	77115	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	34
85014776	77115	Livestock::Poultry[]::Housing::Type::drinking_system	drinking_nipples	\N	4
85014777	77115	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	4
85014778	77115	Livestock::Poultry[]::Excretion::animals	1000	\N	4
85014779	77115	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	4
85014780	77115	Livestock::Poultry[]::Excretion::inp_n_excretion	Standard	\N	4
85014781	77115	Livestock::Poultry[]::Housing::Type::housing_type	branched	\N	4
85014782	77115	Livestock::Poultry[]::Housing::Type::manure_removal_interval	branched	\N	4
85014783	77115	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	4
85014771	77115	Livestock::Poultry[]::Grazing::free_range	yes	\N	34
85014775	77115	Livestock::Poultry[]::Grazing::free_range	yes	\N	4
85014878	77117	Storage::Slurry[]::EFLiquid::contains_pig_manure	no	\N	5
85014879	77117	Storage::Slurry[]::EFLiquid::contains_cattle_manure	yes	\N	5
85014880	77117	Storage::Slurry[]::EFLiquid::cover_type	uncovered	\N	5
85014881	77117	Storage::Slurry[]::mixing_frequency	at_most_2_times_per_year	\N	5
85014882	77117	Storage::Slurry[]::EFLiquid::free_correction_factor	0	\N	5
85014916	77117	Livestock::DairyCow[]::Excretion::CMilk::milk_yield	7500	\N	29
85014917	77117	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_silage_winter	0	\N	29
85014918	77117	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_potatoes_winter	0	\N	29
85014919	77117	Livestock::DairyCow[]::Excretion::CConcentrates::amount_summer	0	\N	29
85014920	77117	Livestock::DairyCow[]::Excretion::CConcentrates::amount_winter	0	\N	29
85014921	77117	Livestock::DairyCow[]::Housing::Type::housing_type_flattened00_Tied Housing Slurry	50	\N	29
85014922	77117	Livestock::DairyCow[]::Housing::Type::housing_type_flattened03_Loose Housing Slurry Plus Solid Manure	0	\N	29
85014923	77117	Livestock::DairyCow[]::Housing::Type::housing_type_flattened04_Loose Housing Deep Litter	0	\N	29
85014927	77117	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_silage_summer	0	\N	29
85014928	77117	Livestock::DairyCow[]::Housing::Type::housing_type_flattened01_Tied Housing Slurry Plus Solid Manure	0	\N	29
85014931	77117	Livestock::DairyCow[]::Excretion::inp_n_excretion	Standard	\N	29
85014932	77117	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_pellets_summer	0	\N	29
85014933	77117	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_beets_winter	0	\N	29
85014934	77117	Livestock::DairyCow[]::Housing::Type::housing_type_flattened02_Loose Housing Slurry	50	\N	29
85014940	77117	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_hay_summer	0	\N	29
85014941	77117	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_grass_silage_winter	0	\N	29
85014942	77117	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_pellets_winter	0	\N	29
85014943	77117	Livestock::DairyCow[]::Housing::Type::housing_type	flattened	\N	29
85014947	77117	Livestock::DairyCow[]::Housing::CFreeFactor::free_correction_factor	0	\N	29
85014924	77117	Livestock::DairyCow[]::Excretion::dimensioning_barn	200	\N	29
85014938	77117	Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor	none	\N	29
85014930	77117	Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	29
85014937	77117	Livestock::DairyCow[]::Outdoor::grazing_days	200	\N	29
85035375	77153	Storage::Slurry[]::EFLiquid::contains_pig_manure	no	\N	2
85035376	77153	Storage::Slurry[]::EFLiquid::contains_cattle_manure	yes	\N	2
85035377	77153	Storage::Slurry[]::EFLiquid::cover_type	uncovered	\N	2
85035378	77153	Storage::Slurry[]::mixing_frequency	at_most_2_times_per_year	\N	2
85035379	77153	Storage::Slurry[]::EFLiquid::free_correction_factor	0	\N	2
85035380	77153	Storage::Slurry[]::depth	2	\N	2
85035381	77153	Storage::Slurry[]::volume	1000	\N	2
85035412	77153	Livestock::Poultry[]::Excretion::animals	1000	\N	18
85035415	77153	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	18
85035416	77153	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	18
85035417	77153	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	18
85035418	77153	Livestock::Poultry[]::Housing::Type::drinking_system_flattened00_drinking nipples	40	\N	18
85035419	77153	Livestock::Poultry[]::Housing::Type::drinking_system_flattened01_bell drinkers	60	\N	18
85035420	77153	Livestock::Poultry[]::Housing::Type::drinking_system	flattened	\N	18
85035421	77153	Livestock::Poultry[]::Housing::Type::manure_removal_interval	branched	\N	18
85035422	77153	Livestock::Poultry[]::Housing::Type::housing_type	branched	\N	18
85035414	77153	Livestock::Poultry[]::Grazing::free_range	yes	\N	18
85245906	77615	Livestock::DairyCow[]::Yard::exercise_yard_flattened03_available roughage is exclusively supplied in the exercise yard	0	\N	23
85245907	77615	Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened00_solid floor	50	\N	23
85245908	77615	Livestock::DairyCow[]::Yard::exercise_yard_flattened00_not available	0	\N	23
85245909	77615	Livestock::DairyCow[]::Yard::exercise_yard_flattened02_available roughage is partly supplied in the exercise yard	50	\N	23
85245910	77615	Livestock::Equides[]::Excretion::animals	0	\N	28
85245912	77615	Livestock::DairyCow[]::Excretion::inp_n_excretion	Standard	\N	23
85245913	77615	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_hay_summer	0	\N	23
85245914	77615	Livestock::DairyCow[]::Excretion::CMilk::milk_yield	7500	\N	23
85245915	77615	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_silage_summer	0	\N	23
85245916	77615	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_pellets_summer	0	\N	23
85245917	77615	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_silage_winter	0	\N	23
85245918	77615	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_grass_silage_winter	0	\N	23
85245919	77615	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_beets_winter	0	\N	23
85245920	77615	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_pellets_winter	0	\N	23
85245921	77615	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_potatoes_winter	0	\N	23
85245922	77615	Livestock::DairyCow[]::Excretion::CConcentrates::amount_summer	1	\N	23
85245923	77615	Livestock::DairyCow[]::Excretion::CConcentrates::amount_winter	2	\N	23
85245924	77615	Livestock::DairyCow[]::Housing::Type::housing_type	flattened	\N	23
85245925	77615	Livestock::DairyCow[]::Housing::Type::housing_type_flattened02_Loose Housing Slurry	50	\N	23
85245926	77615	Livestock::DairyCow[]::Housing::Type::housing_type_flattened01_Tied Housing Slurry Plus Solid Manure	0	\N	23
85245927	77615	Livestock::DairyCow[]::Housing::Type::housing_type_flattened04_Loose Housing Deep Litter	0	\N	23
85245928	77615	Livestock::DairyCow[]::Housing::Type::housing_type_flattened00_Tied Housing Slurry	50	\N	23
85245929	77615	Livestock::DairyCow[]::Housing::Type::housing_type_flattened03_Loose Housing Slurry Plus Solid Manure	0	\N	23
85245933	77615	Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened01_raised feeding stands	0	\N	23
85245934	77615	Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened00_none	50	\N	23
85245935	77615	Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened02_floor with cross slope and collection gutter	0	\N	23
85245936	77615	Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened03_floor with cross slope and collection gutter and raised feeding stands	50	\N	23
85245937	77615	Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened04_toothed scrapper running over a grooved floor	0	\N	23
85245930	77615	Livestock::DairyCow[]::Excretion::dimensioning_barn	200	\N	23
85245932	77615	Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor	flattened	\N	23
85245941	77615	Livestock::DairyCow[]::Housing::CFreeFactor::free_correction_factor	0	\N	23
85245944	77615	Livestock::DairyCow[]::Yard::exercise_yard_flattened01_available roughage is not supplied in the exercise yard	50	\N	23
85245946	77615	Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened02_perforated floor	0	\N	23
85245947	77615	Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened01_unpaved floor	50	\N	23
85245949	77615	Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened03_paddock or pasture used as exercise yard	0	\N	23
85245960	77615	Storage::Slurry[]::depth	3	\N	9
85245961	77615	Storage::Slurry[]::mixing_frequency_flattened00_at most 2 times per year	0	\N	9
85245962	77615	Storage::Slurry[]::mixing_frequency	flattened	\N	9
85245963	77615	Storage::Slurry[]::mixing_frequency_flattened01_3 to 6 times per year	0	\N	9
85245964	77615	Storage::Slurry[]::mixing_frequency_flattened03_13 to 20 times per year	0	\N	9
85245965	77615	Storage::Slurry[]::mixing_frequency_flattened05_more than 30 times per year	0	\N	9
85245966	77615	Storage::Slurry[]::mixing_frequency_flattened04_21 to 30 times per year	0	\N	9
85245967	77615	Storage::Slurry[]::EFLiquid::cover_type	flattened	\N	9
85245968	77615	Storage::Slurry[]::EFLiquid::cover_type_flattened00_uncovered	50	\N	9
85245969	77615	Storage::Slurry[]::EFLiquid::cover_type_flattened01_solid cover	50	\N	9
85245970	77615	Storage::Slurry[]::EFLiquid::cover_type_flattened02_perforated cover	0	\N	9
85245971	77615	Storage::Slurry[]::EFLiquid::cover_type_flattened04_floating cover	0	\N	9
85245972	77615	Storage::Slurry[]::EFLiquid::cover_type_flattened03_tent	0	\N	9
85245973	77615	Storage::Slurry[]::EFLiquid::cover_type_flattened05_natural crust	0	\N	9
85245974	77615	Storage::Slurry[]::EFLiquid::free_correction_factor	0	\N	9
85245975	77615	Storage::Slurry[]::EFLiquid::contains_pig_manure	yes	\N	9
85246001	77615	Livestock::OtherCattle[]::Excretion::animals	0	\N	3
85246002	77615	Livestock::OtherCattle[]::Excretion::inp_n_excretion	Standard	\N	3
85246003	77615	Livestock::OtherCattle[]::Housing::Type::housing_type_flattened02_Loose Housing Slurry	50	\N	3
85246004	77615	Livestock::OtherCattle[]::Housing::Type::housing_type	flattened	\N	3
85246005	77615	Livestock::OtherCattle[]::Housing::Type::housing_type_flattened01_Tied Housing Slurry Plus Solid Manure	0	\N	3
85246006	77615	Livestock::OtherCattle[]::Housing::Type::housing_type_flattened00_Tied Housing Slurry	50	\N	3
85246007	77615	Livestock::OtherCattle[]::Housing::Type::housing_type_flattened03_Loose Housing Slurry Plus Solid Manure	00	\N	3
85246008	77615	Livestock::OtherCattle[]::Housing::Type::housing_type_flattened04_Loose Housing Deep Litter	0	\N	3
85246012	77615	Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened00_none	100	\N	3
85246013	77615	Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened01_raised feeding stands	0	\N	3
85246077	77615	Livestock::FatteningPigs[]::Excretion::inp_n_excretion	Standard	\N	35
85245945	77615	Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard	flattened	\N	23
85246009	77615	Livestock::OtherCattle[]::Excretion::dimensioning_barn	200	\N	3
85246011	77615	Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor	flattened	\N	3
85246014	77615	Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened02_floor with cross slope and collection gutter	0	\N	3
85246015	77615	Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened03_floor with cross slope and collection gutter and raised feeding stands	0	\N	3
85246016	77615	Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened04_toothed scrapper running over a grooved floor	0	\N	3
85246020	77615	Livestock::OtherCattle[]::Housing::CFreeFactor::free_correction_factor	0	\N	3
85246023	77615	Livestock::OtherCattle[]::Yard::exercise_yard_flattened00_not available	0	\N	3
85246024	77615	Livestock::OtherCattle[]::Yard::exercise_yard_flattened01_available roughage is not supplied in the exercise yard	100	\N	3
85246025	77615	Livestock::OtherCattle[]::Yard::exercise_yard_flattened02_available roughage is partly supplied in the exercise yard	0	\N	3
85246026	77615	Livestock::OtherCattle[]::Yard::exercise_yard_flattened03_available roughage is exclusively supplied in the exercise yard	0	\N	3
85246028	77615	Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened00_solid floor	50	\N	3
85246029	77615	Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened01_unpaved floor	50	\N	3
85246030	77615	Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened02_perforated floor	0	\N	3
85246031	77615	Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened03_paddock or pasture used as exercise yard	0	\N	3
85246036	77615	Livestock::OtherCattle[]::Excretion::animalcategory	suckling_cows	\N	3
85246037	77615	Livestock::Equides[]::Excretion::inp_n_excretion	Standard	\N	28
85246044	77615	Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL_flattened00_solid floor	50	\N	28
85246045	77615	Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL_flattened01_unpaved floor	50	\N	28
85246046	77615	Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL_flattened02_paddock or pasture used as exercise yard	0	\N	28
85246049	77615	Livestock::Equides[]::Excretion::animalcategory	horses_older_than_3yr	\N	28
85246050	77615	Livestock::FatteningPigs[]::Excretion::inp_n_excretion	Standard	\N	10
85246051	77615	Livestock::FatteningPigs[]::Excretion::feeding_phase_1_crude_protein	170	\N	10
85246052	77615	Livestock::FatteningPigs[]::Excretion::feeding_phase_2_crude_protein	170	\N	10
85246053	77615	Livestock::FatteningPigs[]::Excretion::energy_content	14	\N	10
85246054	77615	Livestock::FatteningPigs[]::Excretion::feeding_phase_3_crude_protein	170	\N	10
85246055	77615	Livestock::FatteningPigs[]::Housing::Type::housing_type	branched	\N	10
85246059	77615	Livestock::FatteningPigs[]::Housing::CFreeFactor::free_correction_factor	0	\N	10
85246061	77615	Livestock::FatteningPigs[]::Housing::AirScrubber::air_scrubber	none	\N	10
85246063	77615	Storage::Slurry[]::mixing_frequency_flattened02_7 to 12 times per year	100	\N	9
85246064	77615	Storage::Slurry[]::EFLiquid::contains_cattle_manure	no	\N	9
85246069	77615	Livestock::FatteningPigs[]::Housing::CFreeFactor::free_correction_factor	0	\N	35
85246070	77615	Livestock::FatteningPigs[]::Excretion::feeding_phase_3_crude_protein	170	\N	35
85246071	77615	Livestock::FatteningPigs[]::Housing::Type::housing_type	branched	\N	35
85246073	77615	Livestock::FatteningPigs[]::Excretion::feeding_phase_2_crude_protein	170	\N	35
85246074	77615	Livestock::FatteningPigs[]::Housing::AirScrubber::air_scrubber	none	\N	35
85246076	77615	Livestock::FatteningPigs[]::Excretion::feeding_phase_1_crude_protein	170	\N	35
85246027	77615	Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard	flattened	\N	3
85246034	77615	Livestock::OtherCattle[]::Outdoor::grazing_days	200	\N	3
85246035	77615	Livestock::OtherCattle[]::Outdoor::grazing_hours	12	\N	3
85246021	77615	Livestock::OtherCattle[]::Outdoor::yard_days	100	\N	3
85246022	77615	Livestock::OtherCattle[]::Outdoor::exercise_yard	flattened	\N	3
85246033	77615	Livestock::OtherCattle[]::Outdoor::free_correction_factor	0	\N	3
85246062	77615	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor	none	\N	10
85246060	77615	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air	branched	\N	10
85246039	77615	Livestock::Equides[]::Housing::CFreeFactor::free_correction_factor	0	\N	28
85246079	77615	Livestock::FatteningPigs[]::Excretion::energy_content	15	\N	35
85246080	77615	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor	none	\N	35
85246078	77615	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air	branched	\N	35
85246038	77615	Livestock::Equides[]::Outdoor::grazing_days	200	\N	28
85246042	77615	Livestock::Equides[]::Outdoor::yard_hours	12	\N	28
85246041	77615	Livestock::Equides[]::Outdoor::yard_days	100	\N	28
85246043	77615	Livestock::Equides[]::Outdoor::floor_properties_exercise_yard	flattened	\N	28
85246048	77615	Livestock::Equides[]::Outdoor::free_correction_factor	0	\N	28
85253454	77651	Livestock::DairyCow[]::Outdoor::yard_days	250	\N	27
85253496	77651	Storage::Slurry[]::mixing_frequency_flattened05_more than 30 times per year	5	\N	16
85253439	77651	Storage::Slurry[]::EFLiquid::contains_pig_manure	no	\N	27
85253440	77651	Storage::Slurry[]::EFLiquid::contains_cattle_manure	yes	\N	27
85253441	77651	Storage::Slurry[]::EFLiquid::cover_type	uncovered	\N	27
85253442	77651	Storage::Slurry[]::mixing_frequency	at_most_2_times_per_year	\N	27
85253443	77651	Storage::Slurry[]::EFLiquid::free_correction_factor	0	\N	27
85253444	77651	Storage::Slurry[]::depth	2	\N	27
85253445	77651	Storage::Slurry[]::volume	1000	\N	27
85253453	77651	Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard	solid_floor	\N	27
85253458	77651	Livestock::DairyCow[]::Housing::Type::housing_type	Tied_Housing_Slurry	\N	27
85253459	77651	Livestock::DairyCow[]::Excretion::CConcentrates::amount_summer	2	\N	27
85253460	77651	Livestock::DairyCow[]::Excretion::CConcentrates::amount_winter	2	\N	27
85253482	77651	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_potatoes_winter	0	\N	27
85253483	77651	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_grass_silage_winter	0	\N	27
85253484	77651	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_pellets_winter	0	\N	27
85253485	77651	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_silage_winter	0	\N	27
85253486	77651	Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_beets_winter	0	\N	27
85253487	77651	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_pellets_summer	0	\N	27
85253488	77651	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_silage_summer	0	\N	27
85253489	77651	Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_hay_summer	0	\N	27
85253490	77651	Livestock::DairyCow[]::Excretion::CMilk::milk_yield	6500	\N	27
85253493	77651	Storage::Slurry[]::EFLiquid::contains_cattle_manure_flattened01_no	0	\N	16
85253494	77651	Storage::Slurry[]::EFLiquid::cover_type_flattened05_natural crust	5	\N	16
85253495	77651	Storage::Slurry[]::EFLiquid::cover_type_flattened04_floating cover	0	\N	16
85253497	77651	Storage::Slurry[]::mixing_frequency_flattened04_21 to 30 times per year	10	\N	16
85253498	77651	Storage::Slurry[]::volume	1000	\N	16
85253499	77651	Storage::Slurry[]::depth	3	\N	16
85253500	77651	Storage::Slurry[]::EFLiquid::free_correction_factor	0	\N	16
85253501	77651	Storage::Slurry[]::EFLiquid::contains_pig_manure	flattened	\N	16
85253502	77651	Storage::Slurry[]::EFLiquid::contains_cattle_manure	flattened	\N	16
85253503	77651	Storage::Slurry[]::EFLiquid::cover_type_flattened03_tent	0	\N	16
85253504	77651	Storage::Slurry[]::EFLiquid::cover_type_flattened01_solid cover	75	\N	16
85253505	77651	Storage::Slurry[]::EFLiquid::cover_type	flattened	\N	16
85253506	77651	Storage::Slurry[]::mixing_frequency_flattened01_3 to 6 times per year	20	\N	16
85253507	77651	Storage::Slurry[]::EFLiquid::contains_pig_manure_flattened00_yes	100	\N	16
85253508	77651	Storage::Slurry[]::EFLiquid::contains_cattle_manure_flattened00_yes	100	\N	16
85253509	77651	Storage::Slurry[]::EFLiquid::cover_type_flattened02_perforated cover	15	\N	16
85253510	77651	Storage::Slurry[]::EFLiquid::contains_pig_manure_flattened01_no	0	\N	16
85253511	77651	Storage::Slurry[]::EFLiquid::cover_type_flattened00_uncovered	5	\N	16
85253512	77651	Storage::Slurry[]::mixing_frequency_flattened03_13 to 20 times per year	15	\N	16
85720516	61996	Livestock::DairyCow[]::Excretion::animals	30	\N	12
85253513	77651	Storage::Slurry[]::mixing_frequency_flattened02_7 to 12 times per year	50	\N	16
85253514	77651	Storage::Slurry[]::mixing_frequency_flattened00_at most 2 times per year	0	\N	16
85253515	77651	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	32
85253516	77651	Livestock::Poultry[]::Housing::Type::drinking_system	drinking_nipples	\N	32
85253517	77651	Livestock::Poultry[]::Housing::Type::housing_type_flattened03_deep litter	0	\N	32
85253518	77651	Livestock::Poultry[]::Housing::Type::housing_type_flattened01_manure belt without manure belt drying system	30	\N	32
85253519	77651	Livestock::Poultry[]::Outdoor::free_range_flattened00_yes	5	\N	32
85253520	77651	Livestock::Poultry[]::Outdoor::free_range_flattened01_no	5	\N	32
85253522	77651	Livestock::Poultry[]::Housing::Type::drinking_system	flattened	\N	31
85253523	77651	Livestock::Poultry[]::Housing::Type::drinking_system_flattened00_drinking nipples	40	\N	31
85253524	77651	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	31
85253526	77651	Livestock::Poultry[]::Outdoor::free_range_flattened01_no	20	\N	1
85253527	77651	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	1
85253528	77651	Livestock::Poultry[]::Housing::Type::drinking_system	drinking_nipples	\N	1
85253521	77651	Livestock::Poultry[]::Grazing::free_range	flattened	\N	32
85253525	77651	Livestock::Poultry[]::Grazing::free_range	flattened	\N	1
85253529	77651	Livestock::Poultry[]::Housing::Type::manure_removal_interval	less_than_twice_a_month	\N	1
85253530	77651	Livestock::Poultry[]::Housing::Type::housing_type	branched	\N	31
85253531	77651	Livestock::Poultry[]::Housing::Type::manure_removal_interval	branched	\N	31
85253532	77651	Livestock::Poultry[]::Housing::Type::drinking_system_flattened01_bell drinkers	60	\N	31
85253533	77651	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	31
85253534	77651	Livestock::Poultry[]::Excretion::animals	1000	\N	31
85253536	77651	Livestock::Poultry[]::Housing::Type::drinking_system	drinking_nipples	\N	13
85253537	77651	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	31
85253538	77651	Livestock::Poultry[]::Outdoor::free_range_flattened00_yes	80	\N	1
85253539	77651	Livestock::Poultry[]::Housing::Type::housing_type	branched	\N	13
85253540	77651	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	13
85253541	77651	Livestock::Poultry[]::Excretion::animals	100	\N	1
85253542	77651	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	1
85253543	77651	Livestock::Poultry[]::Housing::Type::housing_type	manure_belt_with_manure_belt_drying_system	\N	1
85253544	77651	Livestock::Poultry[]::Excretion::animals	1000	\N	13
85253545	77651	Livestock::Poultry[]::Housing::Type::manure_removal_interval	branched	\N	13
85253546	77651	Livestock::Poultry[]::Excretion::animalcategory	layers	\N	13
85253547	77651	Livestock::Poultry[]::Housing::Type::housing_type_flattened00_manure belt with manure belt drying system	20	\N	32
85253549	77651	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	1
85253550	77651	Livestock::Poultry[]::Housing::AirScrubber::air_scrubber	none	\N	13
85253551	77651	Livestock::Poultry[]::Housing::Type::housing_type_flattened02_deep pit	50	\N	32
85253552	77651	Livestock::Poultry[]::Housing::Type::housing_type	flattened	\N	32
85253553	77651	Livestock::Poultry[]::Excretion::animals	100	\N	32
85253554	77651	Livestock::Poultry[]::Housing::CFreeFactor::free_correction_factor	0	\N	32
85253555	77651	Livestock::Poultry[]::Housing::Type::manure_removal_interval	less_than_twice_a_month	\N	32
85253556	77651	Livestock::Poultry[]::Excretion::animalcategory	growers	\N	32
85253557	77651	Storage::Slurry[]::mixing_frequency	flattened	\N	16
85253535	77651	Livestock::Poultry[]::Grazing::free_range	yes	\N	31
85253548	77651	Livestock::Poultry[]::Grazing::free_range	yes	\N	13
85720517	61996	Livestock::DairyCow[]::Excretion::animals	30	\N	11
85720518	61996	Livestock::Pig[]::Excretion::animals	20	\N	22
85720519	61996	Livestock::Pig[]::Excretion::dimensioning_barn	20	\N	22
85720520	61996	Livestock::FatteningPigs[]::Excretion::animals	20	\N	22
85720521	61996	Livestock::FatteningPigs[]::Excretion::dimensioning_barn	20	\N	22
82475507	61996	Livestock::FatteningPigs[]::Excretion::feeding_phase_1_crude_protein	135	\N	22
85720522	61996	Livestock::FatteningPigs[]::Housing::Type::housing_type	Slurry_Conventional	\N	22
85720523	61996	Livestock::FatteningPigs[]::Housing::AirScrubber::air_scrubber	none	\N	22
85720524	61996	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor	none	\N	22
85720525	61996	Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air	none	\N	22
85720526	61996	Livestock::Poultry[]::Excretion::dimensioning_barn	30	\N	22
83129312	67813	Livestock::Equides[]::Outdoor::grazing_hours	12	\N	7
85246040	77615	Livestock::Equides[]::Outdoor::grazing_hours	12	\N	28
83129282	67813	Livestock::Equides[]::Outdoor::yard_hours	8	\N	7
\.


--
-- Data for Name: data_instance; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.data_instance (data_instance_id, data_instance_dataset, data_instance_name, data_instance_order) FROM stdin;
1	77651	1Flattened	\N
2	77153	Simple	\N
3	77615	SC	\N
4	77115	B2	\N
5	77117	Simple	\N
6	77115	Simple	\N
7	67813	EQ1	\N
8	67813	DC1	\N
9	77615	L	\N
10	77615	pf	\N
11	61996	Stall Milchkühe	\N
12	61996	MKühe	\N
13	77651	Branched	\N
14	67813	FP1	\N
15	61996	Güllelager	\N
16	77651	4Flattened	\N
17	67813	DC2	\N
18	77153	BranchedAndFlattened	\N
19	61996	Stall Aufzuchtrinder unter 1-jährig	\N
20	67813	OC1	\N
21	67813	Lager 1	\N
22	61996	Test	\N
23	77615	DC	\N
24	61996	Stall Aufzuchtrinder 1- bis 2-jährig	\N
25	67813	SR1	\N
26	61996	Stall Aufzuchtrinder über 2-jährig	\N
27	77651	Simple	\N
28	77615	HU	\N
29	77117	DC	\N
30	67813	P1	\N
31	77651	Mixed	\N
32	77651	2Flattened	\N
33	67813	PO1	\N
34	77115	Branched	\N
35	77615	pf2	\N
\.


--
-- Data for Name: dataset; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.dataset (dataset_id, dataset_name, dataset_pers, dataset_mod_date, dataset_version, dataset_comment, dataset_model, dataset_readonly, dataset_guivariant, dataset_modelvariant, dataset_created) FROM stdin;
67813	TestKantonal	1	2021-06-02 11:32:38.91167	6.0	Test2	SingleLU	f	Single	Kantonal_LU	\N
77115	TestBranched	1	2021-03-30 17:03:28.483615	6.0	\N	RegionalSHL	f	Regional	Base	\N
77651	TestRegional	1	2018-08-16 11:58:04.908396	6.0	\N	RegionalSHL	f	Regional	Base	\N
77117	TestFlattened	1	2021-03-15 11:32:50.001544	6.0	\N	RegionalSHL	f	Regional	Base	\N
77153	TestBranchedFlattened	1	2020-12-19 17:27:07.817371	6.0	\N	RegionalSHL	f	Regional	Base	\N
77615	TestRegTK	1	2018-08-31 14:22:18.715566	6.0	\N	RegionalSHL	f	Regional	Base	\N
61824	TestNoAnimals	1	2018-07-26 15:27:48.017416	6.0	\N	SingleSHL	f	Single	Base	\N
61996	TestSingle	1	2021-06-12 11:14:00.019255	6.0	\N	SingleSHL	f	Single	Base	\N
\.


--
-- Data for Name: news; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.news (news_id, news_newsty, news_date, news_text) FROM stdin;
2	1	2009-12-14	Robustere Grafik (Zoom-Funktion im Bar-Graph)
5	1	2009-12-14	Neuer Tabellarischer Report: TAN-Fluss
6	1	2009-12-13	Login-Infos: Neuigkeiten seit der letzten Benutzung
1	1	2009-12-14	Datensatz-Auswahl-Fenster überarbeitet, neu mit Menu-Bar oben und Haupt-Funktionen als Buttons unten
3	1	2009-12-14	Identische Reihenfolge der Ausgabe-Grössen in Grafiken und Tabellarischen Reports
4	2	2009-12-14	Überarbeitete Eingabeparameter-Bezeichnungen/Beschreibungen
10	0	2009-01-01	Willkommen zu Agrammon. Im naechsten Fenster haben Sie die Moeglichkeit, einen leeren Datensatz anzulegen oder einen der bestehenden Demo-Datensaetze als Ausgangspunkt fuer Ihre Simulationen zu kopieren.
11	1	2010-05-15	Datensatz-Organisation: Datensaetze koennen mit "Tags" (Markern) versehen werden und die Datensatztabelle kann nach diesen Tags gefiltert werden.<br /> Im Datensatz-Auswahlfenster kann diese Funktion mit dem Knopf rechts oben ein- bzw. ausgeschaltet werden.
12	1	2010-05-15	Datensatz-Auswahl: Die Musterdatensaetze werden neu nicht mehr in der Datensatzliste angezeigt.<br /> Beim Erzeugen neuer Datensaetze kann aus der Liste der Musterdatensaetze ausgewaehlt werden
13	1	2010-05-15	Validierung Eingabe-Parameter: soweit moeglich werden Eingaben schon im Web-Interface auf ihre Gueltigkeit geprueft (z.B. Prozentangaben zwischen 0 und 100%).<br />Zusaetzliche Validierungen werden beim Rechnen der Simulation durchgefuehrt und Fehler bzw. Warnungen in einem Popup-Fenster angezeigt.
14	1	2010-05-15	Hilfe Eingabe-Parameter: die Hilfefunktion (Info-Symbol in den Eingabezeilen) wurde um Angaben zu Gueltigkeitsbereichen und Datentypen erweitert
15	2	2010-05-15	Kleinere Korrekturen im Simulations-Code
16	2	2019-02-05	<h2>Das Modell Agrammon wurde aktualisiert (Agrammon Version 5.0)</h2><p>Die neue Version enthält die folgenden Änderungen:</p><h3>Modell</h3><ul><li>N-Ausscheidung einzelner Nutztierkategorien gemäss GRUD 2017(Richner et al. (2017).</li><li>Änderung Anteil von TAN in den Ausscheidungen von Rindvieh (Milchkühe undübriges Rindvieh) von 60% auf 55%.</li><li>Verluste von N durch Lachgas (N2O), Stickstoffmonoxid (NO) und elementarenStickstoff (N2) werden neu zur Korrektur des N-Flusses verwendet.</li><li>Emissionsraten mineralische N-Dünger: Anwendung differenzierter Emissionsraten nachDüngertyp.</li><li>Emissionen aus landwirtschaftlichen Böden und Pflanzenbeständen werden neunicht mehr berücksichtigt.</li><li>N-Ausscheidung: Option Standard und Eingabe Wert für N-Ausscheidung:bei Auswahl Standard wird der Richtwert der Stickstoffausscheidunggemäss GRUD 2017 (Richner et al. (2017) verwendet. Bei Eingabe einerZahl kann der Wert für die Stickstoffausscheidung selbst gewähltwerden.</li></ul><h3>Neue Parameter</h3><p>Emissionsmindernde Massnahmen Laufställe Rindvieh:</p><ul><li>Fressgang erhöht zum Laufgang</li><li>Boden mit Quergefälle und Harnsammelrinne</li><li>Fressgang erhöht zum Laufgang und Boden mit Quergefälle undHarnsammelrinne</li></ul><p>Aufstallung Zucht- und Mastschweine:</p><ul><li>Nicht wärmegedämmte Ställe mit freier Lüftung (Aussenklimaställe) undMikroklimabereichen</li><li>Emissionsmindernde  Massnahme Zuluftführung für Ställe Zucht- und Mastschweine:  <ul>    <li>Impulsarme Zuluftführung mit Rieselkanal- oder Futterganglüftung</li>  </ul>  </li></ul><p>Geflügel:</p><ul>  <li>Häufigkeit Betrieb Kotbandentmistung Lege-, Junghennen:    <ul>      <li>Zusätzliche Kategorie: 1 mal pro Tag</li>    </ul>  </li>  <li>Tränkesystem:    <ul>      <li>neue Benennung: Nicht tropfendes Tränkesystem (vorher: Nippeltränke)</li>    </ul>  </li>  <p>Neue Tierkategorien:</p>  <ul>    <li>Übriges Rindvieh:      <ul>        <li>Mutterkühe, schwer</li>        <li>Mutterkühe, mittelschwer</li>        <li>Mutterkühe, leicht</li>      </ul>      <p>(vorher nur eine Kategorie Mutterkühe)</p>    </li>      <li>Kategorie andere Raufutterverzehrer, Kaninchen:      <ul>        <li>Damhirsch; 1 Muttertier und Nachwuchs bis 16 Mt</li>        <li>Rothirsch; 1 Muttertier und Nachwuchs bis 16 Mt</li>        <li>Wapiti; 1 Muttertier und Nachwuchs bis 16 Mt</li>        <li>Bison über 3-jährig</li>        <li>Bison unter 3-jährig</li>        <li>Lama über 2-jährig</li>        <li>Lama unter 2-jährig</li>        <li>Alpaca über 2-jährig</li>        <li>Alpaca unter 2-jährig</li>        <li>Kaninchen:          <ul>            <li>Produzierende Zibbe (inkl. Jungtier bis ca.35 d)</li>            <li>Kaninchen-Jungtier (ab ca. 35 d)</li>          </ul>        </li>      </ul>    </li>  </ul>  <p>Detailliertere Informationen sind  unter <a href="http://www.agrammon.ch/dokumente-zum-download/">Mitteilungen zum Model Agrammon</a>  verfügbar.</p><p>Richner, W., Flisch, R., Mayer, J.,Schlegel, P., Zähner, M., Menzi, H., 2017. 4/ Eigenschaften undAnwendung von Düngern, in: Richner, W., Sinaj, S. (Eds.), Grundlagenfür die Düngung landwirtschaftlicher Kulturen in der Schweiz / GRUD2017. Agrarforschung Schweiz 8 (6) Spezialpublikation, pp. 4/1-4/23.</p><h2>Le modèle Agrammon a été mis à jour (Agrammon Version 5.0)</h2><p>La nouvelle version comprend les modifications suivantes:</p><h3>Nouveaux paramètres d‘entrée et nouvelles options</h3><ul><li>L’excrétion de N de quelques catégories d’animaux a été révisée d’après PRIF 2017 (Richner et al., 2017) (PRIF: « Principes de la fertilisation des cultures agricoles en Suisse »).</li><li>La proportion de TAN (N soluble) dans les excrétions des bovins (vaches laitières et autres bovins) a été réduite de 60 % à 55 %.</li><li>Les pertes en N sous forme de protoxyde d’azote (N2O), de monoxyde d’azote (NO) et d’azote élémentaire (N2) sont désormais utilisées pour corriger le flux de N.</li><li>Utilisation de taux d’émission différenciés par type d’engrais minéraux azotés.</li><li>Désormais, les émissions des sols agricoles et de la végétation ne sont plus prises en compte.</li><li>Si "Standard" est introduisé, la valeur de référence pour les excrétions azotées d'après PRIF 2017 (Richner et al., 2017). Si un nombre est introduisé, une valeur pour les excrétions azotées peut être déterminée par l'utilisateur/-trice.</li></ul><h3>Nouveaux paramètres</h3><p>Mesures limitant les émissions dans les stabulations pour bovins:</p><ul><li>Stalle d’affouragement surélevée</li><li>Sol non perforé avec pente transversale et rigole de collecte de l’urine</li><li>Sol non perforé avec pente transversale et rigole de collecte de l’urine et stalle d’affouragement surélevée</li></ul><p>Type de stabulation pour porcs:</p><ul><li>Stabulation sans isolation thermique : porcheries sans isolation thermique à ventilation naturelle (stabulation à climat extérieur) et à zones de microclimat.</li><li>Mesures limitant les émissions amenée d'air:<ul>  <li>Alimentation d'air à faible im</li></ul></li></ul><p>Volaille:</p><ul>  <li>Fréquence d'évacuation du fumier par le tapis:    <ul>      <li>Catégorie supplémentaire: une fois par jour</li>    </ul>  </li>  <li>Type d'abreuvoir:    <ul>      <li>Changement de nom: «Abreuvoir empêchant les fuites» (précédemment: «Abreuvoir à sucette»)</li>    </ul>  </li>  <p>Nouvelles catégories d’animaux:</p>  <ul>    <li>Autres bovins:      <ul>        <li>Vache allaitante, races lourdes</li>        <li>Vache allaitante, races moyennes</li>        <li>Vache allaitante, races légères</li>      </ul>      <p>(précédemment: uniquement une catégorie de vache allaitante)</p>    </li>      <li>Autres animaux consommant des fourrages grossiers:      <ul>        <li>Daim / Daim; mère plus petits jusqu’à 16 mois</li>        <li>Cerf / Cerf; mère plus petits jusqu’à 16 mois</li>        <li>Wapiti / Wapiti; mère plus petits jusqu’à 16 mois</li>        <li>Bison de plus de 3 ans</li>        <li>Bison de moins de 3 ans</li>        <li>Lama de plus de 3 ans</li>        <li>Lama de moins de 3 ans</li>        <li>Alpaga de plus de 3 ans</li>        <li>Alpaga de moins de 3 ans</li>        <li>Lapin: lapereau inclus jusqu'à 35 jours</li>        <li>Lapin: lapereau à partir d</li>      </ul>    </li>  </ul>  <p>De plus amples informations sont disponibles dans le document <a href="https://www.agrammon.ch/documents-t-l-charger/">«Informations concernant le modèle Agrammon»</a>.</p><p>Richner, W., Flisch, R., Mayer, J.,Schlegel, P., Zähner, M., Menzi, H., 2017. 4/ Eigenschaften undAnwendung von Düngern, in: Richner, W., Sinaj, S. (Eds.), Grundlagenfür die Düngung landwirtschaftlicher Kulturen in der Schweiz / GRUD2017. Agrarforschung Schweiz 8 (6) Spezialpublikation, pp. 4/1-4/23.</p>
\.


--
-- Data for Name: newsty; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.newsty (newsty_id, newsty_name) FROM stdin;
1	Web-Interface
2	Simulationsmodell
0	Allgemein
\.


--
-- Data for Name: pers; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.pers (pers_id, pers_email, pers_first, pers_last, pers_password, pers_org, pers_last_login, pers_created, pers_role, pers_old_password) FROM stdin;
1	fritz.zaucker@oetiker.ch	Fritz	Zaucker	$2a$06$786kq1GGlf5Jo574bqT2UepCstZsO7cqX2ApI1TelUPsUSTP/Ol.C	\N	2021-06-10 15:56:54.016102	\N	0	grfg12
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.role (role_id, role_name) FROM stdin;
0	admin
1	user
2	support
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.session (session_id, session_state, session_expiration) FROM stdin;
AUfr5KAEsBkDs5DqFHntbu3Ul7E8BKbaieEJ4keUieXfPCNypxtzqe13m7dpDXZD	{\n  "username": null,\n  "logged-in": false\n}	2021-06-12 12:13:06.69843
pI4Q3PKtEkopW7wIQHCZzHbD2NUAxsQDPTkpKDgfiBx6aegpAUuDP4I3FBjo7kYW	{\n  "logged-in": false,\n  "username": null\n}	2021-06-12 12:13:06.819511
EeM0v5RkAxjzvE7bvWMXPkH7l9yIhmTHE84Qje6YeeCGLYQQqN09amkVlbMsd4Sp	{\n  "username": null,\n  "logged-in": false\n}	2021-06-12 12:13:06.833211
8Pwe4cJVPdrr5JETVJ8KRmjgBM4aksKlD48FndQA7x97pzudG3DwYZoO6VIUyrHK	{\n  "username": null,\n  "logged-in": false\n}	2021-06-12 12:13:07.56842
eDq7eehYkUlgh9LVgoza5dcDvw7mgm24q5hdCWWM9Chi1asgE4GBwFm42yNm2XN2	{\n  "username": null,\n  "logged-in": false\n}	2021-06-12 12:13:07.609101
KJCejJsUyJtEZXqrs8Dc5kUgp6LcOYACpLycxdWIhL3GhmM5R3kEogwvYszGvICL	{\n  "logged-in": false,\n  "username": null\n}	2021-06-12 12:13:07.629626
mywgp4qBF093OvT1Ht2t0GFgP3E8WRHDxmTcwHLYOf0aB5ysHaZ2O14udUb1lVNz	{\n  "logged-in": false,\n  "username": null\n}	2021-06-12 12:13:07.996993
W4dbivXYpYNX06e9snUhx4WvnjhSGiejN6f7L3hACJW6OMjTyaC8aaclh9RNbM3N	{\n  "username": null,\n  "logged-in": false\n}	2021-06-12 12:13:08.026559
6X9b9INTjUBiqZaaE8mFtve8BrZiEP8xooJl972CPP9BSe5MHl4Dzxe0On6L4R3p	{\n  "logged-in": false,\n  "username": null\n}	2021-06-12 12:13:08.027553
ItSlhmz6IGLpq3bj1V2Iw0WnyiKWBXYBM5ZHGpgCX7pgDYT4hBRnfDESVwf6DUBQ	{\n  "logged-in": false,\n  "username": null\n}	2021-06-12 12:13:08.068897
w48VjrHG6shbJjhJ3KQ4k38lu0IjY1zOFwjWk2PsQoW18kZC2vWqlkvRUTG9OYYz	{\n  "username": null,\n  "logged-in": false\n}	2021-06-12 12:13:08.08017
u60S9D6TtI2CgBjhi0D3Govb4DOXRaZmrnpqtMxf0j2MWY2k6NudFYIDBv6AfTiL	{\n  "logged-in": false,\n  "username": null\n}	2021-06-12 12:13:08.081016
jto3YlgDMnsDmtkOMy7cKLIDxbvKgIf6NHSKUR2ll41BX873sdH9jnrkGINQb54N	{\n  "logged-in": false,\n  "username": null\n}	2021-06-12 12:13:08.091386
KAzdWDTvUcCyiasjnIkbQg0Blqpg8Zo4vRrtJHg4IQM8YlKzEbu8Nv06DVUH1WUt	{\n  "username": null,\n  "logged-in": false\n}	2021-06-12 12:13:08.092307
iQT4sbrDntBMWWpTbc0jN23xGytM8NIO2HusMPhjuBXCI4Mo5IToAwLnHBqhEOs3	{\n  "logged-in": true,\n  "username": "fritz.zaucker@oetiker.ch"\n}	2021-06-12 12:14:02.034248
\.


--
-- Data for Name: tag; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.tag (tag_id, tag_name, tag_pers) FROM stdin;
1	HR2002	1
2	HR2007	1
3	Regional	1
4	Testing	1
5	Newtag4	1
10	Fritz	1
23	test	1
39	Kurs 17.5.2010	1
44	Kurs 21.5.2010	1
74	Neues PostIt	1
109	täst	1
\.


--
-- Data for Name: tagds; Type: TABLE DATA; Schema: public; Owner: agrammon
--

COPY public.tagds (tagds_id, tagds_tag, tagds_dataset) FROM stdin;
\.


--
-- Name: api_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.api_tokens_id_seq', 1, false);


--
-- Name: branches_branches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.branches_branches_id_seq', 41412, true);


--
-- Name: data_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.data_data_id_seq', 85720713, true);


--
-- Name: data_instance_data_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.data_instance_data_instance_id_seq', 35, true);


--
-- Name: dataset_dataset_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.dataset_dataset_id_seq', 78958, true);


--
-- Name: news_news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.news_news_id_seq', 16, true);


--
-- Name: newsty_newsty_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.newsty_newsty_id_seq', 2, true);


--
-- Name: pers_pers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.pers_pers_id_seq', 2452, true);


--
-- Name: role_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.role_role_id_seq', 2, true);


--
-- Name: tag_tag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.tag_tag_id_seq', 297, true);


--
-- Name: tagds_tagds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agrammon
--

SELECT pg_catalog.setval('public.tagds_tagds_id_seq', 1538, true);


--
-- Name: api_tokens api_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT api_tokens_pkey PRIMARY KEY (id);


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
-- Name: data data_data_var_key; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data
    ADD CONSTRAINT data_data_var_key UNIQUE (data_var, data_instance_id, data_dataset);


--
-- Name: data_instance data_instance_dataset_name_key; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_instance
    ADD CONSTRAINT data_instance_dataset_name_key UNIQUE (data_instance_dataset, data_instance_name);


--
-- Name: data_instance data_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_instance
    ADD CONSTRAINT data_instance_pkey PRIMARY KEY (data_instance_id);


--
-- Name: data data_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data
    ADD CONSTRAINT data_pkey PRIMARY KEY (data_id);


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
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (session_id);


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
-- Name: data_data_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX data_data_dataset ON public.data USING btree (data_dataset);


--
-- Name: data_data_id_data_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX data_data_id_data_dataset ON public.data USING btree (data_id, data_dataset);


--
-- Name: dataset_dataset_name_dataset_pers_dataset_version_dataset_m_idx; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE UNIQUE INDEX dataset_dataset_name_dataset_pers_dataset_version_dataset_m_idx ON public.dataset USING btree (dataset_name, dataset_pers, dataset_version, dataset_modelvariant, dataset_guivariant);


--
-- Name: dataset_dataset_pers; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX dataset_dataset_pers ON public.dataset USING btree (dataset_pers);


--
-- Name: tagds_tagds_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX tagds_tagds_dataset ON public.tagds USING btree (tagds_dataset);


--
-- Name: tagds_tagds_tag_tagds_dataset_idx; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE UNIQUE INDEX tagds_tagds_tag_tagds_dataset_idx ON public.tagds USING btree (tagds_tag, tagds_dataset);


--
-- Name: branches branches_branches_var_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_branches_var_fkey FOREIGN KEY (branches_var) REFERENCES public.data(data_id) ON DELETE CASCADE;


--
-- Name: data data_data_dataset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data
    ADD CONSTRAINT data_data_dataset_fkey FOREIGN KEY (data_dataset) REFERENCES public.dataset(dataset_id) ON DELETE CASCADE;


--
-- Name: data data_data_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data
    ADD CONSTRAINT data_data_instance_id_fkey FOREIGN KEY (data_instance_id) REFERENCES public.data_instance(data_instance_id) ON DELETE CASCADE;


--
-- Name: data_instance data_instance_data_instance_dataset_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.data_instance
    ADD CONSTRAINT data_instance_data_instance_dataset_fkey FOREIGN KEY (data_instance_dataset) REFERENCES public.dataset(dataset_id) ON DELETE CASCADE;


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
-- Name: TABLE data; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.data TO agrammon_user;


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
-- Name: SEQUENCE data_data_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,UPDATE ON SEQUENCE public.data_data_id_seq TO agrammon_user;


--
-- Name: TABLE data_instance; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.data_instance TO agrammon_user;


--
-- Name: SEQUENCE data_instance_data_instance_id_seq; Type: ACL; Schema: public; Owner: agrammon
--

GRANT SELECT,UPDATE ON SEQUENCE public.data_instance_data_instance_id_seq TO agrammon_user;


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

\unrestrict etJtfvqpC1gidDhHbLhpEhLE9bwgwFanhOi6yN73yveoYA1ivIM4Dlx6hSKZGIT

