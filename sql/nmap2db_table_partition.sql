-- --------------------------------------------------
-- NMAP2DB
-- 
-- NMAP2DB is a set of scripts that can be used to run 
-- automatic NMAP scans of a network and save the results 
-- in a database for further analysis.
--
-- @File: 
-- nmap2pg_table_partition.sql
--
-- @Author: 
-- Rafael Martinez Guerrero / rafael@postgresql.org.es
-- 
-- @Description: 
-- This file installs all the functions necessary to
-- manage partitions of host_info, service_info and
-- scan_report tables
-- --------------------------------------------------


\connect nmap2db postgres

BEGIN;

CREATE OR REPLACE FUNCTION create_nmap2db_partitions_tables() RETURNS VOID
LANGUAGE plpgsql 
SECURITY DEFINER 
SET search_path = public, pg_temp
AS $$
DECLARE
 v_partition_table VARCHAR(128);
 v_partition_table_exists BOOLEAN;
 v_trigger_exists BOOLEAN;

 v_date TIMESTAMP := now();
 v_date_from TIMESTAMP;
 v_date_to TIMESTAMP;

 v_table_owner VARCHAR(128) := 'nmap2db_role_rw';

 BEGIN
   --
   -- This funcion will create the partitions tables, functions and triggers 
   -- neccesary when using partitioning for host_info, service_info and
   -- scan_report tables.
   --
   -- This function should be executed via crontab at least one time every month.
   -- If the funcion is not run at least one time every month, the database
   -- will stop working after two months without running the function.
   -- 

   v_date_from := date_trunc('month', v_date);
   v_date_to := date_trunc('month', v_date + '1 month'::interval);

   
    --
    -- Table scan_report partition for current month
    --

    v_partition_table := 'scan_report_' || EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from);

    SELECT COUNT(*) = 1 INTO v_partition_table_exists FROM pg_tables WHERE schemaname = 'public' AND tablename = v_partition_table;
    SELECT COUNT(*) = 1 INTO v_trigger_exists FROM pg_trigger WHERE tgname = 'scan_report_insert';

    IF NOT v_partition_table_exists THEN

        EXECUTE 'CREATE TABLE ' || v_partition_table || 
		' (PRIMARY KEY (report_id), ' ||
		'FOREIGN KEY (scan_jobid) REFERENCES scan_job (id) MATCH FULL ON DELETE CASCADE, ' ||
		'CHECK (registered >= ''' || v_date_from || ''' AND registered < ''' || v_date_to || ''')) INHERITS (scan_report)';
	
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_registered_idx ON ' || v_partition_table || '(registered)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_started_idx ON ' || v_partition_table || '(started)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_finished_idx ON ' || v_partition_table || '(finished)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_elapsed_time_idx ON ' || v_partition_table || '(elapsed_time)';

	EXECUTE 'CREATE TRIGGER extract_report_values BEFORE INSERT ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE extract_report_values()';
	EXECUTE 'CREATE TRIGGER extract_hosts_and_services_values AFTER INSERT ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE extract_hosts_and_services_values()';

    END IF;

    --
    -- Table scan_report partition for next month
    --

    v_partition_table := 'scan_report_' || EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval);

    SELECT COUNT(*) = 1 INTO v_partition_table_exists FROM pg_tables WHERE schemaname = 'public' AND tablename = v_partition_table;
    SELECT COUNT(*) = 1 INTO v_trigger_exists FROM pg_trigger WHERE tgname = 'scan_report_insert';

    IF NOT v_partition_table_exists THEN

        EXECUTE 'CREATE TABLE ' || v_partition_table || 
		' (PRIMARY KEY (report_id), ' ||
		'FOREIGN KEY (scan_jobid) REFERENCES scan_job (id) MATCH FULL ON DELETE CASCADE, ' ||
		'CHECK (registered >= ''' || v_date_from + '1 month'::interval || 
		''' AND registered < ''' || v_date_to + '1 month'::interval || ''')) INHERITS (scan_report)';
	
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_registered_idx ON ' || v_partition_table || '(registered)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_started_idx ON ' || v_partition_table || '(started)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_finished_idx ON ' || v_partition_table || '(finished)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_elapsed_time_idx ON ' || v_partition_table || '(elapsed_time)';

	EXECUTE 'CREATE TRIGGER extract_report_values BEFORE INSERT ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE extract_report_values()';
	EXECUTE 'CREATE TRIGGER extract_hosts_and_services_values AFTER INSERT ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE extract_hosts_and_services_values()';
	
    END IF;

   --
   -- Create RULES used for partitioning
   --

   EXECUTE '
CREATE OR REPLACE RULE current_month AS ON INSERT TO scan_report
WHERE (registered >= DATE ''' || v_date_from || ''' AND registered < DATE ''' || v_date_to || ''' )
DO INSTEAD INSERT INTO ' || 'scan_report_' || EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from) || ' VALUES (NEW.*)
';

   EXECUTE '
CREATE OR REPLACE RULE next_month AS ON INSERT TO scan_report
WHERE (registered >= DATE ''' || v_date_from  + '1 month'::interval || ''' AND registered < DATE ''' || v_date_to + '1 month'::interval || ''' )
DO INSTEAD INSERT INTO ' || 'scan_report_' || EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval) || ' VALUES (NEW.*)                                  
';


   --
   -- Table host_info partition for current month
   --

   v_partition_table := 'host_info_' || EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from);

   SELECT COUNT(*) = 1 INTO v_partition_table_exists FROM pg_tables WHERE schemaname = 'public' AND tablename = v_partition_table;
   SELECT COUNT(*) = 1 INTO v_trigger_exists FROM pg_trigger WHERE tgname = 'host_info_insert';

   IF NOT v_partition_table_exists THEN

        EXECUTE 'CREATE TABLE ' || v_partition_table || 
		' (PRIMARY KEY (report_id,hostaddr), '||
		'FOREIGN KEY (report_id) REFERENCES scan_report_' ||
		EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from) ||
		' (report_id) MATCH FULL ON DELETE CASCADE, ' ||
		'FOREIGN KEY (hostaddr) REFERENCES hostaddress (hostaddr) MATCH FULL ON DELETE CASCADE,' || 
		' CHECK (registered >= ''' || v_date_from || 
		''' AND registered < ''' || v_date_to || ''')) INHERITS (host_info)';
	
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_registered_idx ON ' || v_partition_table || '(registered)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_scan_started_idx ON ' || v_partition_table || '(scan_started)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_scan_finished_idx ON ' || v_partition_table || '(scan_finished)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_hostaddr_idx ON ' || v_partition_table || '(hostaddr)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_state_idx ON ' || v_partition_table || '(state)';

	EXECUTE 'CREATE TRIGGER update_last_scanned AFTER INSERT ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE update_last_scanned();';
	EXECUTE 'CREATE TRIGGER decrease_total_scans AFTER DELETE ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE decrease_total_scans()';

   END IF; 

   
   --
   -- Table host_info partition for next month
   --

   v_partition_table := 'host_info_' || EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval);

   SELECT COUNT(*) = 1 INTO v_partition_table_exists FROM pg_tables WHERE schemaname = 'public' AND tablename = v_partition_table;
  
   IF NOT v_partition_table_exists THEN

        EXECUTE 'CREATE TABLE ' || v_partition_table || 
		' (PRIMARY KEY (report_id,hostaddr), ' ||
		'FOREIGN KEY (report_id) REFERENCES scan_report_' ||
		EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval) ||
		' (report_id) MATCH FULL ON DELETE CASCADE, ' ||
		'FOREIGN KEY (hostaddr) REFERENCES hostaddress (hostaddr) MATCH FULL ON DELETE CASCADE,' || 
		' CHECK (registered >= ''' || v_date_from + '1 month'::interval || 
		''' AND registered < ''' || v_date_to + '1 month'::interval || ''')) INHERITS (host_info)';
	
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_registered_idx ON ' || v_partition_table || '(registered)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_scan_started_idx ON ' || v_partition_table || '(scan_started)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_scan_finished_idx ON ' || v_partition_table || '(scan_finished)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_hostaddr_idx ON ' || v_partition_table || '(hostaddr)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_state_idx ON ' || v_partition_table || '(state)';
    
	EXECUTE 'CREATE TRIGGER update_last_scanned AFTER INSERT ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE update_last_scanned();';
	EXECUTE 'CREATE TRIGGER decrease_total_scans AFTER DELETE ON ' || v_partition_table || ' FOR EACH ROW EXECUTE PROCEDURE decrease_total_scans()';
   END IF;
       
   --
   -- Create RULES used for partitioning
   --

   EXECUTE '
CREATE OR REPLACE RULE current_month AS ON INSERT TO host_info
WHERE (registered >= DATE ''' || v_date_from || ''' AND registered < DATE ''' || v_date_to || ''' )
DO INSTEAD INSERT INTO ' || 'host_info_' || EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from) || ' VALUES (NEW.*)
';

   EXECUTE '
CREATE OR REPLACE RULE next_month AS ON INSERT TO host_info
WHERE (registered >= DATE ''' || v_date_from  + '1 month'::interval || ''' AND registered < DATE ''' || v_date_to + '1 month'::interval || ''' )
DO INSTEAD INSERT INTO ' || 'host_info_' || EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval) || ' VALUES (NEW.*)                                  
';
 
  
    --
    -- Table service_info partition for current month
    --

    v_partition_table := 'service_info_' || EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from);

    SELECT COUNT(*) = 1 INTO v_partition_table_exists FROM pg_tables WHERE schemaname = 'public' AND tablename = v_partition_table;
    SELECT COUNT(*) = 1 INTO v_trigger_exists FROM pg_trigger WHERE tgname = 'service_info_insert';

    IF NOT v_partition_table_exists THEN

        EXECUTE 'CREATE TABLE ' || v_partition_table || 
	' (PRIMARY KEY (report_id, hostaddr, port_protocol, port_id), ' ||
	'FOREIGN KEY (report_id) REFERENCES scan_report_' ||
	EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from) ||
	' (report_id) MATCH FULL ON DELETE CASCADE, ' ||
	'FOREIGN KEY (hostaddr) REFERENCES hostaddress (hostaddr) MATCH FULL ON DELETE CASCADE,' || 
	'CHECK (registered >= ''' || v_date_from || ''' AND registered < ''' || v_date_to || ''')) INHERITS (service_info)';
	
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_registered_idx ON ' || v_partition_table || '(registered)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_hostaddr_idx ON ' || v_partition_table || '(hostaddr)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_port_protocol_idx ON ' || v_partition_table || '(port_protocol)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_port_id_idx ON ' || v_partition_table || '(port_id)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_port_state_idx ON ' || v_partition_table || '(port_state)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_service_idx ON ' || v_partition_table || '(service)';

     END IF;
     
     --
     -- Table service_info partition for next month
     --

     v_partition_table := 'service_info_' || EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval);

     SELECT COUNT(*) = 1 INTO v_partition_table_exists FROM pg_tables WHERE schemaname = 'public' AND tablename = v_partition_table;
  
     IF NOT v_partition_table_exists THEN

        EXECUTE 'CREATE TABLE ' || v_partition_table || 
	' (PRIMARY KEY (report_id, hostaddr, port_protocol, port_id), ' ||
	'FOREIGN KEY (report_id) REFERENCES scan_report_' ||
	EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval) ||
	' (report_id) MATCH FULL ON DELETE CASCADE, ' ||
	'FOREIGN KEY (hostaddr) REFERENCES hostaddress (hostaddr) MATCH FULL ON DELETE CASCADE,' || 
	'CHECK (registered >= ''' || v_date_from + '1 month'::interval || 
	''' AND registered < ''' || v_date_to + '1 month'::interval || ''')) INHERITS (service_info)';
	
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_registered_idx ON ' || v_partition_table || '(registered)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_hostaddr_idx ON ' || v_partition_table || '(hostaddr)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_port_protocol_idx ON ' || v_partition_table || '(port_protocol)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_port_id_idx ON ' || v_partition_table || '(port_id)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_port_state_idx ON ' || v_partition_table || '(port_state)';
	EXECUTE 'CREATE INDEX ' || v_partition_table || '_service_idx ON ' || v_partition_table || '(service)';

     END IF;

   --
   -- Create RULES used for partitioning
   --

   EXECUTE '
CREATE OR REPLACE RULE current_month AS ON INSERT TO service_info
WHERE (registered >= DATE ''' || v_date_from || ''' AND registered < DATE ''' || v_date_to || ''' )
DO INSTEAD INSERT INTO ' || 'service_info_' || EXTRACT(YEAR FROM v_date_from) || '_' || EXTRACT(MONTH FROM v_date_from) || ' VALUES (NEW.*)
';

   EXECUTE '
CREATE OR REPLACE RULE next_month AS ON INSERT TO service_info
WHERE (registered >= DATE ''' || v_date_from  + '1 month'::interval || ''' AND registered < DATE ''' || v_date_to + '1 month'::interval || ''' )
DO INSTEAD INSERT INTO ' || 'service_info_' || EXTRACT(YEAR FROM v_date_from + '1 month'::interval) || '_' || EXTRACT(MONTH FROM v_date_from + '1 month'::interval) || ' VALUES (NEW.*)                                  
';


  EXECUTE 'GRANT SELECT ON all tables in schema public to nmap2db_role_ro';

  RETURN;
 END;
$$;

ALTER FUNCTION create_nmap2db_partitions_tables() OWNER TO nmap2db_role_rw;

COMMIT;