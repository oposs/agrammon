--
-- PostgreSQL database dump
--

-- Dumped from database version 16.6 (Ubuntu 16.6-1.pgdg22.04+1)
-- Dumped by pg_dump version 16.6 (Ubuntu 16.6-1.pgdg22.04+1)

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
-- Name: audit; Type: SCHEMA; Schema: -; Owner: agrammon
--

CREATE SCHEMA audit;


ALTER SCHEMA audit OWNER TO agrammon;

--
-- Name: SCHEMA audit; Type: COMMENT; Schema: -; Owner: agrammon
--

COMMENT ON SCHEMA audit IS 'Out-of-table audit/history logging tables and trigger functions';


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
-- Name: audit_table(regclass); Type: FUNCTION; Schema: audit; Owner: agrammon
--

CREATE FUNCTION audit.audit_table(target_table regclass) RETURNS void
    LANGUAGE sql
    AS $_$
    SELECT audit.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$_$;


ALTER FUNCTION audit.audit_table(target_table regclass) OWNER TO agrammon;

--
-- Name: FUNCTION audit_table(target_table regclass); Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass) IS '
Add auditing support to the given table. Row-level changes will be logged with
full client query text. No cols are ignored.
';


--
-- Name: audit_table(regclass, boolean, boolean); Type: FUNCTION; Schema: audit; Owner: agrammon
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean) RETURNS void
    LANGUAGE sql
    AS $_$
    SELECT audit.audit_table($1, $2, $3, ARRAY[]::TEXT[]);
$_$;


ALTER FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean) OWNER TO agrammon;

--
-- Name: audit_table(regclass, boolean, boolean, text[]); Type: FUNCTION; Schema: audit; Owner: agrammon
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE
    stm_targets TEXT = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
    _q_txt TEXT;
    _ignored_cols_snip TEXT = '';
    BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table::TEXT;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table::TEXT;

    IF audit_rows THEN
      IF array_length(ignored_cols,1) > 0 THEN
          _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
      END IF;
      _q_txt = 'CREATE TRIGGER audit_trigger_row '
               'AFTER INSERT OR UPDATE OR DELETE ON ' ||
               target_table::TEXT ||
               ' FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func(' ||
               quote_literal(audit_query_text) ||
               _ignored_cols_snip ||
               ');';
      RAISE NOTICE '%', _q_txt;
      EXECUTE _q_txt;
      stm_targets = 'TRUNCATE';
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
             target_table ||
             ' FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('||
             quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%', _q_txt;
    EXECUTE _q_txt;
    END;
$$;


ALTER FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) OWNER TO agrammon;

--
-- Name: FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]); Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) IS '
Add auditing support to a table.

Arguments:
 target_table:     Table name, schema qualified if not on search_path
 audit_rows:       Record each row change, or only audit at a statement level
 audit_query_text: Record the text of the client query that triggered
                   the audit event?
 ignored_cols:     Columns to exclude from update diffs,
                   ignore updates that change only ignored cols.
';


--
-- Name: if_modified_func(); Type: FUNCTION; Schema: audit; Owner: agrammon
--

CREATE FUNCTION audit.if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
    DECLARE
      audit_row audit.log;
      include_values BOOLEAN;
      log_diffs BOOLEAN;
      h_old JSONB;
      h_new JSONB;
      excluded_cols TEXT[] = ARRAY[]::TEXT[];
    BEGIN
    IF TG_WHEN <> 'AFTER' THEN
      RAISE EXCEPTION 'audit.if_modified_func() may only run as an AFTER trigger';
    END IF;

    audit_row = ROW(
      nextval('audit.log_id_seq'),                    -- id
      TG_TABLE_SCHEMA::TEXT,                          -- schema_name
      TG_TABLE_NAME::TEXT,                            -- table_name
      TG_RELID,                                       -- relation OID for faster searches
      session_user::TEXT,                             -- session_user_name
      current_user::TEXT,                             -- current_user_name
      current_timestamp,                              -- action_tstamp_tx
      statement_timestamp(),                          -- action_tstamp_stm
      clock_timestamp(),                              -- action_tstamp_clk
      txid_current(),                                 -- transaction ID
      current_setting('audit.application_name', true),      -- client application
      current_setting('audit.application_user_name', true), -- client user name
      inet_client_addr(),                             -- client_addr
      inet_client_port(),                             -- client_port
      current_query(),                                -- top-level query or queries
      substring(TG_OP, 1, 1),                         -- action
      NULL,                                           -- row_data
      NULL,                                           -- changed_fields
      'f'                                             -- statement_only
    );

    IF NOT TG_ARGV[0]::BOOLEAN IS DISTINCT FROM 'f'::BOOLEAN THEN
      audit_row.client_query = NULL;
    END IF;

    IF TG_ARGV[1] IS NOT NULL THEN
      excluded_cols = TG_ARGV[1]::TEXT[];
    END IF;

    IF (TG_OP = 'INSERT' AND TG_LEVEL = 'ROW') THEN
      audit_row.changed_fields = to_jsonb(NEW.*) - excluded_cols;
    ELSIF (TG_OP = 'UPDATE' AND TG_LEVEL = 'ROW') THEN
      audit_row.row_data = to_jsonb(OLD.*) - excluded_cols;
      audit_row.changed_fields =
        (to_jsonb(NEW.*) - audit_row.row_data) - excluded_cols;
      IF audit_row.changed_fields = '{}'::JSONB THEN
        -- All changed fields are ignored. Skip this update.
        RETURN NULL;
      END IF;
    ELSIF (TG_OP = 'DELETE' AND TG_LEVEL = 'ROW') THEN
      audit_row.row_data = to_jsonb(OLD.*) - excluded_cols;
    ELSIF (TG_LEVEL = 'STATEMENT' AND
           TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
      audit_row.statement_only = 't';
    ELSE
      RAISE EXCEPTION '[audit.if_modified_func] - Trigger func added as trigger '
                      'for unhandled case: %, %', TG_OP, TG_LEVEL;
      RETURN NULL;
    END IF;
    INSERT INTO audit.log VALUES (audit_row.*);
    RETURN NULL;
    END;
$$;


ALTER FUNCTION audit.if_modified_func() OWNER TO agrammon;

--
-- Name: FUNCTION if_modified_func(); Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON FUNCTION audit.if_modified_func() IS '
Track changes to a table at the statement and/or row level.

Optional parameters to trigger in CREATE TRIGGER call:

param 0: BOOLEAN, whether to log the query text. Default ''t''.

param 1: TEXT[], columns to ignore in updates. Default [].

       Updates to ignored cols are omitted from changed_fields.

       Updates with only ignored cols changed are not inserted
       into the audit log.

       Almost all the processing work is still done for updates
       that ignored. If you need to save the load, you need to use
       WHEN clause on the trigger instead.

       No warning or error is issued if ignored_cols contains columns
       that do not exist in the target table. This lets you specify
       a standard set of ignored columns.

There is no parameter to disable logging of values. Add this trigger as
a ''FOR EACH STATEMENT'' rather than ''FOR EACH ROW'' trigger if you do not
want to log row values.

Note that the user name logged is the login role for the session. The audit
trigger cannot obtain the active role because it is reset by
the SECURITY DEFINER invocation of the audit trigger its self.
';


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
-- Name: jsonb_minus(jsonb, text[]); Type: FUNCTION; Schema: public; Owner: agrammon
--

CREATE FUNCTION public.jsonb_minus("left" jsonb, keys text[]) RETURNS jsonb
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT
    CASE
      WHEN "left" ?| "keys"
        THEN COALESCE(
          (SELECT ('{' ||
                    string_agg(to_json("key")::TEXT || ':' || "value", ',') ||
                    '}')
             FROM jsonb_each("left")
            WHERE "key" <> ALL ("keys")),
          '{}'
        )::JSONB
      ELSE "left"
    END
$$;


ALTER FUNCTION public.jsonb_minus("left" jsonb, keys text[]) OWNER TO agrammon;

--
-- Name: FUNCTION jsonb_minus("left" jsonb, keys text[]); Type: COMMENT; Schema: public; Owner: agrammon
--

COMMENT ON FUNCTION public.jsonb_minus("left" jsonb, keys text[]) IS 'Delete specificed keys';


--
-- Name: jsonb_minus(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: agrammon
--

CREATE FUNCTION public.jsonb_minus("left" jsonb, "right" jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT
    COALESCE(json_object_agg(
      "key",
      CASE
        -- if the value is an object and the value of the second argument is
        -- not null, we do a recursion
        WHEN jsonb_typeof("value") = 'object' AND "right" -> "key" IS NOT NULL
        THEN jsonb_minus("value", "right" -> "key")
        -- for all the other types, we just return the value
        ELSE "value"
      END
    ), '{}')::JSONB
  FROM
    jsonb_each("left")
  WHERE
    "left" -> "key" <> "right" -> "key"
    OR "right" -> "key" IS NULL
$$;


ALTER FUNCTION public.jsonb_minus("left" jsonb, "right" jsonb) OWNER TO agrammon;

--
-- Name: FUNCTION jsonb_minus("left" jsonb, "right" jsonb); Type: COMMENT; Schema: public; Owner: agrammon
--

COMMENT ON FUNCTION public.jsonb_minus("left" jsonb, "right" jsonb) IS 'Delete matching pairs in the right argument from the left argument';


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

--
-- Name: -; Type: OPERATOR; Schema: public; Owner: agrammon
--

CREATE OPERATOR public.- (
    FUNCTION = public.jsonb_minus,
    LEFTARG = jsonb,
    RIGHTARG = text[]
);


ALTER OPERATOR public.- (jsonb, text[]) OWNER TO agrammon;

--
-- Name: -; Type: OPERATOR; Schema: public; Owner: agrammon
--

CREATE OPERATOR public.- (
    FUNCTION = public.jsonb_minus,
    LEFTARG = jsonb,
    RIGHTARG = jsonb
);


ALTER OPERATOR public.- (jsonb, jsonb) OWNER TO agrammon;

--
-- Name: OPERATOR - (jsonb, jsonb); Type: COMMENT; Schema: public; Owner: agrammon
--

COMMENT ON OPERATOR public.- (jsonb, jsonb) IS 'Delete matching pairs in the right argument from the left argument';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: log; Type: TABLE; Schema: audit; Owner: agrammon
--

CREATE TABLE audit.log (
    id bigint NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    relid oid NOT NULL,
    session_user_name text NOT NULL,
    current_user_name text NOT NULL,
    action_tstamp_tx timestamp with time zone NOT NULL,
    action_tstamp_stm timestamp with time zone NOT NULL,
    action_tstamp_clk timestamp with time zone NOT NULL,
    transaction_id bigint NOT NULL,
    application_name text,
    application_user_name text,
    client_addr inet,
    client_port integer,
    client_query text,
    action text NOT NULL,
    row_data jsonb,
    changed_fields jsonb,
    statement_only boolean NOT NULL,
    CONSTRAINT log_action_check CHECK ((action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text, 'T'::text])))
);


ALTER TABLE audit.log OWNER TO agrammon;

--
-- Name: TABLE log; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON TABLE audit.log IS 'History of auditable actions on audited tables';


--
-- Name: COLUMN log.id; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.id IS 'Unique identifier for each auditable event';


--
-- Name: COLUMN log.schema_name; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.schema_name IS 'Database schema audited table for this event is in';


--
-- Name: COLUMN log.table_name; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.table_name IS 'Non-schema-qualified table name of table event occured in';


--
-- Name: COLUMN log.relid; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.relid IS 'Table OID. Changes with drop/create. Get with ''tablename''::REGCLASS';


--
-- Name: COLUMN log.session_user_name; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.session_user_name IS 'Login / session user whose statement caused the audited event';


--
-- Name: COLUMN log.current_user_name; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.current_user_name IS 'Effective user that cased audited event (if authorization level changed)';


--
-- Name: COLUMN log.action_tstamp_tx; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.action_tstamp_tx IS 'Transaction start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN log.action_tstamp_stm; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.action_tstamp_stm IS 'Statement start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN log.action_tstamp_clk; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.action_tstamp_clk IS 'Wall clock time at which audited event''s trigger call occurred';


--
-- Name: COLUMN log.transaction_id; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.transaction_id IS 'Identifier of transaction that made the change. Unique when paired with action_tstamp_tx.';


--
-- Name: COLUMN log.application_name; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.application_name IS 'Client-set session application name when this audit event occurred.';


--
-- Name: COLUMN log.application_user_name; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.application_user_name IS 'Client-set session application user when this audit event occurred.';


--
-- Name: COLUMN log.client_addr; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.client_addr IS 'IP address of client that issued query. Null for unix domain socket.';


--
-- Name: COLUMN log.client_port; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.client_port IS 'Port address of client that issued query. Undefined for unix socket.';


--
-- Name: COLUMN log.client_query; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.client_query IS 'Top-level query that caused this auditable event. May be more than one.';


--
-- Name: COLUMN log.action; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.action IS 'Action type; I = insert, D = delete, U = update, T = truncate';


--
-- Name: COLUMN log.row_data; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.row_data IS 'Record value. Null for statement-level trigger. For INSERT this is null. For DELETE and UPDATE it is the old tuple.';


--
-- Name: COLUMN log.changed_fields; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.changed_fields IS 'New values of fields for INSERT or changed by UPDATE. Null for DELETE';


--
-- Name: COLUMN log.statement_only; Type: COMMENT; Schema: audit; Owner: agrammon
--

COMMENT ON COLUMN audit.log.statement_only IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';


--
-- Name: log_id_seq; Type: SEQUENCE; Schema: audit; Owner: agrammon
--

CREATE SEQUENCE audit.log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE audit.log_id_seq OWNER TO agrammon;

--
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: agrammon
--

ALTER SEQUENCE audit.log_id_seq OWNED BY audit.log.id;


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
    dataset_version text DEFAULT '2.0'::text NOT NULL,
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
    pers_password_changed timestamp without time zone,
    pers_activated timestamp without time zone,
    pers_newpassword text,
    pers_newpassword_key text
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
-- Name: data_new_data_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.data_new_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.data_new_data_id_seq OWNER TO agrammon;

--
-- Name: data_new_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.data_new_data_id_seq OWNED BY public.data_new.data_id;


--
-- Name: data_view; Type: VIEW; Schema: public; Owner: agrammon
--

CREATE VIEW public.data_view AS
 SELECT data_id,
    data_dataset,
    COALESCE(replace(data_var, '[]'::text, (('['::text || data_instance) || ']'::text)), data_var) AS data_var,
    data_val,
    data_instance_order,
    data_comment
   FROM public.data_new data
  ORDER BY data_dataset, COALESCE(replace(data_var, '[]'::text, (('['::text || data_instance) || ']'::text)), data_var);


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
-- Name: login; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.login (
    login_id integer NOT NULL,
    login_pers integer NOT NULL,
    login_timestamp timestamp without time zone DEFAULT now() NOT NULL,
    login_sudouser text,
    login_variant text
);


ALTER TABLE public.login OWNER TO agrammon;

--
-- Name: login_login_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.login_login_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.login_login_id_seq OWNER TO agrammon;

--
-- Name: login_login_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.login_login_id_seq OWNED BY public.login.login_id;


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
-- Name: standard6; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.standard6 (
    data_id integer,
    data_dataset integer,
    dataset_version text
);


ALTER TABLE public.standard6 OWNER TO agrammon;

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
-- Name: log id; Type: DEFAULT; Schema: audit; Owner: agrammon
--

ALTER TABLE ONLY audit.log ALTER COLUMN id SET DEFAULT nextval('audit.log_id_seq'::regclass);


--
-- Name: api_tokens id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.api_tokens ALTER COLUMN id SET DEFAULT nextval('public.api_tokens_id_seq'::regclass);


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
-- Name: login login_id; Type: DEFAULT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.login ALTER COLUMN login_id SET DEFAULT nextval('public.login_login_id_seq'::regclass);


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
-- Name: log log_pkey; Type: CONSTRAINT; Schema: audit; Owner: agrammon
--

ALTER TABLE ONLY audit.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


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
-- Name: dataset dataset_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (dataset_id);


--
-- Name: login login_pkey; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT login_pkey PRIMARY KEY (login_id);


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
-- Name: tagds tagds_tagds_tag_tagds_dataset_idx; Type: CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.tagds
    ADD CONSTRAINT tagds_tagds_tag_tagds_dataset_idx UNIQUE (tagds_tag, tagds_dataset);


--
-- Name: log_action_idx; Type: INDEX; Schema: audit; Owner: agrammon
--

CREATE INDEX log_action_idx ON audit.log USING btree (action);


--
-- Name: log_action_tstamp_tx_stm_idx; Type: INDEX; Schema: audit; Owner: agrammon
--

CREATE INDEX log_action_tstamp_tx_stm_idx ON audit.log USING btree (action_tstamp_stm);


--
-- Name: log_relid_idx; Type: INDEX; Schema: audit; Owner: agrammon
--

CREATE INDEX log_relid_idx ON audit.log USING btree (relid);


--
-- Name: data_new_data_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX data_new_data_dataset ON public.data_new USING btree (data_dataset);


--
-- Name: data_new_data_id_data_dataset; Type: INDEX; Schema: public; Owner: agrammon
--

CREATE INDEX data_new_data_id_data_dataset ON public.data_new USING btree (data_id, data_dataset);


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
-- Name: branches audit_trigger_row; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.branches FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: data_new audit_trigger_row; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.data_new FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: dataset audit_trigger_row; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.dataset FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true', '{dataset_mod_date}');


--
-- Name: pers audit_trigger_row; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.pers FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: role audit_trigger_row; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.role FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: tag audit_trigger_row; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.tag FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: tagds audit_trigger_row; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.tagds FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: branches audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.branches FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: data_new audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.data_new FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: dataset audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.dataset FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: pers audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.pers FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: role audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.role FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: tag audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.tag FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: tagds audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: agrammon
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.tagds FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


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
-- Name: login login_login_pers_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agrammon
--

ALTER TABLE ONLY public.login
    ADD CONSTRAINT login_login_pers_fkey FOREIGN KEY (login_pers) REFERENCES public.pers(pers_id);


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

