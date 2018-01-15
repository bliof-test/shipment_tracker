--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.15
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: deployed_apps(json); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION deployed_apps(deploys json) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      BEGIN
        RETURN (SELECT string_agg(elem::json->>'app', ' ')
                FROM json_array_elements_text(deploys) elem);
      END
      $$;


--
-- Name: released_tickets_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION released_tickets_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        new.tsv :=
          setweight(to_tsvector(coalesce(deployed_apps(new.deploys), '')), 'A') ||
          setweight(to_tsvector(coalesce(new.summary, '')), 'B') ||
          setweight(to_tsvector(coalesce(new.description, '')), 'D');
        RETURN new;
      END
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: builds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE builds (
    id integer NOT NULL,
    version character varying,
    success boolean,
    source character varying,
    event_created_at timestamp without time zone,
    url character varying,
    app_name character varying,
    build_type character varying DEFAULT 'unit'::character varying
);


--
-- Name: builds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: builds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE builds_id_seq OWNED BY builds.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: deploys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deploys (
    id integer NOT NULL,
    app_name character varying,
    server character varying,
    version character varying,
    deployed_by character varying,
    deployed_at timestamp without time zone,
    environment character varying,
    region character varying,
    uuid uuid,
    deploy_alert character varying
);


--
-- Name: deploys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deploys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deploys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deploys_id_seq OWNED BY deploys.id;


--
-- Name: event_counts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE event_counts (
    id integer NOT NULL,
    snapshot_name character varying,
    event_id integer
);


--
-- Name: event_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_counts_id_seq OWNED BY event_counts.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE events (
    id integer NOT NULL,
    details json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying,
    uuid uuid DEFAULT uuid_generate_v4()
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: git_repository_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE git_repository_locations (
    id integer NOT NULL,
    uri character varying,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_head character varying
);


--
-- Name: git_repository_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE git_repository_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: git_repository_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE git_repository_locations_id_seq OWNED BY git_repository_locations.id;


--
-- Name: manual_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE manual_tests (
    id integer NOT NULL,
    email character varying,
    versions text[] DEFAULT '{}'::text[],
    accepted boolean,
    comment text,
    created_at timestamp without time zone
);


--
-- Name: manual_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE manual_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manual_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE manual_tests_id_seq OWNED BY manual_tests.id;


--
-- Name: release_exceptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE release_exceptions (
    id integer NOT NULL,
    repo_owner_id integer,
    versions text[] DEFAULT '{}'::text[],
    approved boolean,
    comment text,
    submitted_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    path character varying
);


--
-- Name: release_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE release_exceptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: release_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE release_exceptions_id_seq OWNED BY release_exceptions.id;


--
-- Name: released_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE released_tickets (
    id integer NOT NULL,
    key character varying,
    summary character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tsv tsvector,
    deploys json DEFAULT '[]'::json,
    versions text[] DEFAULT '{}'::text[]
);


--
-- Name: released_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE released_tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: released_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE released_tickets_id_seq OWNED BY released_tickets.id;


--
-- Name: repo_admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE repo_admins (
    id integer NOT NULL,
    name character varying,
    email character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: repo_admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE repo_admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repo_admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE repo_admins_id_seq OWNED BY repo_admins.id;


--
-- Name: repo_ownerships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE repo_ownerships (
    id integer NOT NULL,
    app_name character varying NOT NULL,
    repo_owners character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    repo_approvers character varying
);


--
-- Name: repo_ownerships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE repo_ownerships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repo_ownerships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE repo_ownerships_id_seq OWNED BY repo_ownerships.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tickets (
    id integer NOT NULL,
    key character varying,
    summary character varying,
    status character varying,
    paths text[] DEFAULT '{}'::text[],
    event_created_at timestamp without time zone,
    versions text[] DEFAULT '{}'::text[],
    approved_at timestamp without time zone,
    version_timestamps hstore DEFAULT ''::hstore NOT NULL,
    approved_by character varying,
    developed_by character varying
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tickets_id_seq OWNED BY tickets.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tokens (
    id integer NOT NULL,
    source character varying,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tokens_id_seq OWNED BY tokens.id;


--
-- Name: uatests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE uatests (
    id integer NOT NULL,
    server character varying,
    success boolean,
    test_suite_version character varying,
    event_created_at timestamp without time zone,
    versions text[] DEFAULT '{}'::text[]
);


--
-- Name: uatests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE uatests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: uatests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE uatests_id_seq OWNED BY uatests.id;


--
-- Name: builds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY builds ALTER COLUMN id SET DEFAULT nextval('builds_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: deploys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deploys ALTER COLUMN id SET DEFAULT nextval('deploys_id_seq'::regclass);


--
-- Name: event_counts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_counts ALTER COLUMN id SET DEFAULT nextval('event_counts_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: git_repository_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY git_repository_locations ALTER COLUMN id SET DEFAULT nextval('git_repository_locations_id_seq'::regclass);


--
-- Name: manual_tests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY manual_tests ALTER COLUMN id SET DEFAULT nextval('manual_tests_id_seq'::regclass);


--
-- Name: release_exceptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY release_exceptions ALTER COLUMN id SET DEFAULT nextval('release_exceptions_id_seq'::regclass);


--
-- Name: released_tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY released_tickets ALTER COLUMN id SET DEFAULT nextval('released_tickets_id_seq'::regclass);


--
-- Name: repo_admins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY repo_admins ALTER COLUMN id SET DEFAULT nextval('repo_admins_id_seq'::regclass);


--
-- Name: repo_ownerships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY repo_ownerships ALTER COLUMN id SET DEFAULT nextval('repo_ownerships_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tickets ALTER COLUMN id SET DEFAULT nextval('tickets_id_seq'::regclass);


--
-- Name: tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens ALTER COLUMN id SET DEFAULT nextval('tokens_id_seq'::regclass);


--
-- Name: uatests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY uatests ALTER COLUMN id SET DEFAULT nextval('uatests_id_seq'::regclass);


--
-- Name: builds builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY builds
    ADD CONSTRAINT builds_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: deploys deploys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deploys
    ADD CONSTRAINT deploys_pkey PRIMARY KEY (id);


--
-- Name: event_counts event_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_counts
    ADD CONSTRAINT event_counts_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: git_repository_locations git_repository_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY git_repository_locations
    ADD CONSTRAINT git_repository_locations_pkey PRIMARY KEY (id);


--
-- Name: manual_tests manual_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY manual_tests
    ADD CONSTRAINT manual_tests_pkey PRIMARY KEY (id);


--
-- Name: release_exceptions release_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY release_exceptions
    ADD CONSTRAINT release_exceptions_pkey PRIMARY KEY (id);


--
-- Name: released_tickets released_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY released_tickets
    ADD CONSTRAINT released_tickets_pkey PRIMARY KEY (id);


--
-- Name: repo_admins repo_admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY repo_admins
    ADD CONSTRAINT repo_admins_pkey PRIMARY KEY (id);


--
-- Name: repo_ownerships repo_ownerships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY repo_ownerships
    ADD CONSTRAINT repo_ownerships_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: uatests uatests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY uatests
    ADD CONSTRAINT uatests_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_builds_on_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_version ON builds USING btree (version);


--
-- Name: index_deploys_on_app_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deploys_on_app_name ON deploys USING btree (app_name);


--
-- Name: index_deploys_on_deploy_alert; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deploys_on_deploy_alert ON deploys USING btree (deploy_alert);


--
-- Name: index_deploys_on_server_and_app_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deploys_on_server_and_app_name ON deploys USING btree (server, app_name);


--
-- Name: index_deploys_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deploys_on_uuid ON deploys USING btree (uuid);


--
-- Name: index_deploys_on_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deploys_on_version ON deploys USING btree (version);


--
-- Name: index_events_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_events_on_uuid ON events USING btree (uuid);


--
-- Name: index_git_repository_locations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_git_repository_locations_on_name ON git_repository_locations USING btree (name);


--
-- Name: index_manual_tests_on_versions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_manual_tests_on_versions ON manual_tests USING gin (versions);


--
-- Name: index_release_exceptions_on_repo_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_release_exceptions_on_repo_owner_id ON release_exceptions USING btree (repo_owner_id);


--
-- Name: index_release_exceptions_on_submitted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_release_exceptions_on_submitted_at ON release_exceptions USING btree (submitted_at);


--
-- Name: index_released_tickets_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_released_tickets_on_key ON released_tickets USING btree (key);


--
-- Name: index_released_tickets_on_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_released_tickets_on_tsv ON released_tickets USING gin (tsv);


--
-- Name: index_released_tickets_on_versions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_released_tickets_on_versions ON released_tickets USING gin (versions);


--
-- Name: index_repo_admins_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repo_admins_on_email ON repo_admins USING btree (email);


--
-- Name: index_repo_ownerships_on_app_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repo_ownerships_on_app_name ON repo_ownerships USING btree (app_name);


--
-- Name: index_tickets_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_key ON tickets USING btree (key);


--
-- Name: index_tickets_on_paths; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_paths ON tickets USING gin (paths);


--
-- Name: index_tickets_on_versions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_versions ON tickets USING gin (versions);


--
-- Name: index_tokens_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tokens_on_value ON tokens USING btree (value);


--
-- Name: index_uatests_on_versions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uatests_on_versions ON uatests USING gin (versions);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: released_tickets released_tickets_tsv_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER released_tickets_tsv_update BEFORE INSERT OR UPDATE ON released_tickets FOR EACH ROW EXECUTE PROCEDURE released_tickets_trigger();


--
-- Name: release_exceptions fk_rails_90b3b0f798; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY release_exceptions
    ADD CONSTRAINT fk_rails_90b3b0f798 FOREIGN KEY (repo_owner_id) REFERENCES repo_admins(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20150427164403');

INSERT INTO schema_migrations (version) VALUES ('20150428100731');

INSERT INTO schema_migrations (version) VALUES ('20150428153913');

INSERT INTO schema_migrations (version) VALUES ('20150429132037');

INSERT INTO schema_migrations (version) VALUES ('20150507103704');

INSERT INTO schema_migrations (version) VALUES ('20150619141417');

INSERT INTO schema_migrations (version) VALUES ('20150702151512');

INSERT INTO schema_migrations (version) VALUES ('20150716164920');

INSERT INTO schema_migrations (version) VALUES ('20150720105357');

INSERT INTO schema_migrations (version) VALUES ('20150731133334');

INSERT INTO schema_migrations (version) VALUES ('20150803111222');

INSERT INTO schema_migrations (version) VALUES ('20150803135300');

INSERT INTO schema_migrations (version) VALUES ('20150803152941');

INSERT INTO schema_migrations (version) VALUES ('20150804151329');

INSERT INTO schema_migrations (version) VALUES ('20150807082220');

INSERT INTO schema_migrations (version) VALUES ('20150807113312');

INSERT INTO schema_migrations (version) VALUES ('20150821153011');

INSERT INTO schema_migrations (version) VALUES ('20150823100018');

INSERT INTO schema_migrations (version) VALUES ('20150823124738');

INSERT INTO schema_migrations (version) VALUES ('20150823124740');

INSERT INTO schema_migrations (version) VALUES ('20150823124742');

INSERT INTO schema_migrations (version) VALUES ('20150910135208');

INSERT INTO schema_migrations (version) VALUES ('20150915150206');

INSERT INTO schema_migrations (version) VALUES ('20150915151859');

INSERT INTO schema_migrations (version) VALUES ('20150915161859');

INSERT INTO schema_migrations (version) VALUES ('20150921110831');

INSERT INTO schema_migrations (version) VALUES ('20150921115023');

INSERT INTO schema_migrations (version) VALUES ('20150928130626');

INSERT INTO schema_migrations (version) VALUES ('20150930111438');

INSERT INTO schema_migrations (version) VALUES ('20160209134817');

INSERT INTO schema_migrations (version) VALUES ('20160212113505');

INSERT INTO schema_migrations (version) VALUES ('20160311131953');

INSERT INTO schema_migrations (version) VALUES ('20160315155037');

INSERT INTO schema_migrations (version) VALUES ('20160315165607');

INSERT INTO schema_migrations (version) VALUES ('20160316154428');

INSERT INTO schema_migrations (version) VALUES ('20160318164129');

INSERT INTO schema_migrations (version) VALUES ('20160324142505');

INSERT INTO schema_migrations (version) VALUES ('20160825111503');

INSERT INTO schema_migrations (version) VALUES ('20161216125029');

INSERT INTO schema_migrations (version) VALUES ('20170105131624');

INSERT INTO schema_migrations (version) VALUES ('20170126115241');

INSERT INTO schema_migrations (version) VALUES ('20170127101420');

INSERT INTO schema_migrations (version) VALUES ('20170127120354');

INSERT INTO schema_migrations (version) VALUES ('20170127123616');

INSERT INTO schema_migrations (version) VALUES ('20170407150443');

INSERT INTO schema_migrations (version) VALUES ('20170808075905');

INSERT INTO schema_migrations (version) VALUES ('20171205132454');

INSERT INTO schema_migrations (version) VALUES ('20171219093236');

INSERT INTO schema_migrations (version) VALUES ('20180115135632');

