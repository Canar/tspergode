SET client_encoding = 'UTF8';

CREATE TYPE pagedata AS (
	path character varying(100),
	html text
);
ALTER TYPE pagedata OWNER TO owner;

CREATE FUNCTION getpage(t text) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg(x.tt,'') from (       
    select path,tt from (
            path inner join content  
            on path.contentid=content.id 
        ) inner join getsec(sectionid,sectiontable) gs   
        on gs.it=content.sectionid 
        order by contentid,seq 
    ) x where x.path=t 
    group by x.path;
$$;
ALTER FUNCTION public.getpage(t text) OWNER TO owner;

CREATE FUNCTION getsec(i integer, n name) RETURNS TABLE(it integer, tt text)
    LANGUAGE plpgsql
    AS $$ begin return query execute 
        'select id,cast(html as text) from ' || n || ' where id=' || i  || ' ;';
    end; $$;
ALTER FUNCTION public.getsec(i integer, n name) OWNER TO owner;

CREATE TABLE content (
    id integer NOT NULL,
    sectionid integer NOT NULL,
    sectiontable name NOT NULL,
    seq integer NOT NULL
);
CREATE TABLE path (
    path character varying(100) NOT NULL,
    contentid integer NOT NULL
);
CREATE SEQUENCE content_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE content_id_seq OWNED BY content.id;
CREATE TABLE htmlsection (
    id integer NOT NULL,
    html xml
);
COMMENT ON COLUMN htmlsection.html IS 'xhtml subset';

CREATE SEQUENCE htmlsection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE htmlsection_id_seq OWNED BY htmlsection.id;

CREATE TABLE sectionmap (
    unit integer,
    section integer
);
ALTER TABLE sectionmap OWNER TO owner;

CREATE TABLE template (
    id integer NOT NULL,
    title character varying,
    map integer
);
CREATE SEQUENCE template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE template_id_seq OWNED BY template.id;

CREATE TABLE textsection (
    id integer NOT NULL,
    html text
);
CREATE SEQUENCE textsection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE textsection_id_seq OWNED BY textsection.id;

ALTER TABLE ONLY content ALTER COLUMN id SET DEFAULT nextval('content_id_seq'::regclass);
ALTER TABLE ONLY htmlsection ALTER COLUMN id SET DEFAULT nextval('htmlsection_id_seq'::regclass);
ALTER TABLE ONLY template ALTER COLUMN id SET DEFAULT nextval('template_id_seq'::regclass);
ALTER TABLE ONLY textsection ALTER COLUMN id SET DEFAULT nextval('textsection_id_seq'::regclass);

COPY content (id, sectionid, sectiontable, seq) FROM stdin;
1	1	textsection	1
1	2	textsection	3
1	3	textsection	5
1	1	htmlsection	6
1	5	textsection	2
1	5	textsection	4
1	4	textsection	7
\.

SELECT pg_catalog.setval('content_id_seq', 4, true);

COPY htmlsection (id, html) FROM stdin;
1	<p>Hi there</p>
\.

SELECT pg_catalog.setval('htmlsection_id_seq', 1, true);

COPY path (path, contentid) FROM stdin;
/	1
\.

COPY sectionmap (unit, section) FROM stdin;
\.

COPY template (id, title, map) FROM stdin;
\.

SELECT pg_catalog.setval('template_id_seq', 1, false);

COPY textsection (id, html) FROM stdin;
1	<!DOCTYPE html><head><title>
2	</title></head><body><h1>
3	</h1>
4	</body></html>
5	Page Title
\.
SELECT pg_catalog.setval('textsection_id_seq', 5, true);

ALTER TABLE ONLY content
    ADD CONSTRAINT content_pkey PRIMARY KEY (id, sectionid, sectiontable, seq);
ALTER TABLE ONLY path
    ADD CONSTRAINT contentpath PRIMARY KEY (path, contentid);
ALTER TABLE ONLY htmlsection
    ADD CONSTRAINT pkhtmlsegmentid PRIMARY KEY (id);

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;

