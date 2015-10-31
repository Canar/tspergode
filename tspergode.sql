set client_encoding = 'utf8';

create type pagedata as (
	path character varying(100),
	html text
);
alter type pagedata owner to owner;

create function getpage(t text) returns text
    language sql
    as $$
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
alter function public.getpage(t text) owner to owner;

create function getsec(i integer, n name) returns table(it integer, tt text)
    language plpgsql
    as $$ begin return query execute 
        'select id,cast(html as text) from ' || n || ' where id=' || i  || ' ;';
    end; $$;
alter function public.getsec(i integer, n name) owner to owner;

create table content (
    id integer not null,
    sectionid integer not null,
    sectiontable name not null,
    seq integer not null
);
create table path (
    path character varying(100) not null,
    contentid integer not null
);
create sequence content_id_seq
    start with 1
    increment by 1
    no minvalue
    no maxvalue
    cache 1;
alter sequence content_id_seq owned by content.id;
create table htmlsection (
    id integer not null,
    html xml
);
comment on column htmlsection.html is 'xhtml subset';

create sequence htmlsection_id_seq
    start with 1
    increment by 1
    no minvalue
    no maxvalue
    cache 1;
alter sequence htmlsection_id_seq owned by htmlsection.id;

create table sectionmap (
    unit integer,
    section integer
);
alter table sectionmap owner to owner;

create table template (
    id integer not null,
    title character varying,
    map integer
);
create sequence template_id_seq
    start with 1
    increment by 1
    no minvalue
    no maxvalue
    cache 1;
alter sequence template_id_seq owned by template.id;

create table textsection (
    id integer not null,
    html text
);
create sequence textsection_id_seq
    start with 1
    increment by 1
    no minvalue
    no maxvalue
    cache 1;
alter sequence textsection_id_seq owned by textsection.id;

alter table only content alter column id set default nextval('content_id_seq'::regclass);
alter table only htmlsection alter column id set default nextval('htmlsection_id_seq'::regclass);
alter table only template alter column id set default nextval('template_id_seq'::regclass);
alter table only textsection alter column id set default nextval('textsection_id_seq'::regclass);

copy content (id, sectionid, sectiontable, seq) from stdin;
1	1	textsection	1
1	2	textsection	3
1	3	textsection	5
1	1	htmlsection	6
1	5	textsection	2
1	5	textsection	4
1	4	textsection	7
\.

select pg_catalog.setval('content_id_seq', 4, true);

copy htmlsection (id, html) from stdin;
1	<p>hi there</p>
\.

select pg_catalog.setval('htmlsection_id_seq', 1, true);

copy path (path, contentid) from stdin;
/	1
\.

copy sectionmap (unit, section) from stdin;
\.

copy template (id, title, map) from stdin;
\.

select pg_catalog.setval('template_id_seq', 1, false);

copy textsection (id, html) from stdin;
1	<!doctype html><head><title>
2	</title></head><body><h1>
3	</h1>
4	</body></html>
5	page title
\.
select pg_catalog.setval('textsection_id_seq', 5, true);

alter table only content
    add constraint content_pkey primary key (id, sectionid, sectiontable, seq);
alter table only path
    add constraint contentpath primary key (path, contentid);
alter table only htmlsection
    add constraint pkhtmlsegmentid primary key (id);

revoke all on schema public from public;
revoke all on schema public from postgres;
grant all on schema public to postgres;
grant all on schema public to public;

