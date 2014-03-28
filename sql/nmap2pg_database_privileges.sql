-- ------------------------------------------------------------
-- Privileges
--
-- ------------------------------------------------------------
\connect nmap2db postgres 

BEGIN;
REVOKE ALL ON DATABASE nmap2db FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

REVOKE ALL ON DATABASE nmap2db FROM nmap2db_role_ro;
REVOKE ALL ON SCHEMA public FROM nmap2db_role_ro;

GRANT ALL ON DATABASE nmap2db TO nmap2db_role_rw;
GRANT ALL ON SCHEMA public TO nmap2db_role_rw;

GRANT CONNECT ON DATABASE nmap2db TO nmap2db_role_ro;
GRANT USAGE ON SCHEMA public TO nmap2db_role_ro;

GRANT SELECT ON all tables in schema public to nmap2db_role_ro;
GRANT SELECT ON all sequences in schema public to nmap2db_role_ro;
COMMIT;