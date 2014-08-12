-- --------------------------------------------------
-- NMAP2DB
-- 
-- NMAP2DB is a set of scripts that can be used to run 
-- automatic NMAP scans of a network and save the results 
-- in a database for further analysis.
--
-- @File: 
-- nmap2pg.sql
--
-- @Author: 
-- Rafael Martinez Guerrero / rafael@postgresql.org.es
-- 
-- @Description: 
-- This SQL file has all the PostgreSQL database definitions 
-- needed by NMAP2DB. It needs PostgreSQL >= 9.1
-- --------------------------------------------------

-- DROP DATABASE nmap2db;
-- DROP USER nmap2db_role_rw;
-- DROP USER nmap2db_role_ro;

\echo '\n# [Creating user nmap2db_role_rw]\n'

CREATE USER nmap2db_role_rw;

\echo '\n# [Creating user nmap2db_role_ro]\n'

CREATE USER nmap2db_role_ro;

\echo '\n# [Creating database nmap2db]\n'

CREATE DATABASE nmap2db OWNER nmap2db_role_rw ENCODING 'UTF8';
ALTER DATABASE nmap2db OWNER TO nmap2db_role_rw;

\connect nmap2db postgres

ALTER DATABASE nmap2db SET constraint_exclusion = 'on';

BEGIN;

-- ############################################################
--                      Table  definitions
-- ############################################################

-- ------------------------------------------------------------
-- Table: hostaddress
--
-- @Description: Information about all the IPs included on the 
-- 		 networks defined in the table network.
--
--		 The content of this table is updated automatically
-- 		 when networks get registered or deleted from the 
-- 		 table network. 
--
-- Attributes:
--
-- @hostaddr: IP-address.
-- @registered: Timestamp when the IP was registered.
-- @last_scanned: Timestamp when the IP was last scanned.
-- @total_scans: Total times the IP has beed scanned.
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: hostaddress]\n'

CREATE TABLE hostaddress (
  hostaddr INET NOT NULL ,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_scanned  TIMESTAMP WITH TIME ZONE,
  total_scans BIGINT NOT NULL DEFAULT 0
);

ALTER TABLE hostaddress ADD PRIMARY KEY (hostaddr);
ALTER TABLE hostaddress OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Table: host_info
--
-- @Description: Information about the hosts scanned by a scan 
-- 		 executed by nmap2db. All the information in 
-- 		 this table is extracted automatically when saving 
-- 		 the XML output of a NMAP scan executed with the 
-- 		 -oX paramater.    
--
-- Attributes:
--
-- @report_id: MD5 value of the XML output of the report from where 
-- 	       we extract the host information
--
-- @registered: Timestamp when the host was registered. 
--
-- @scan_started: Timestamp when the scan of the host was started (/host/@starttime).
-- @scan_finished: Timestamp when the scan of the host was finished (/host/@endtime).
-- @hostaddr: IP-address of the host (/host/address/@addr).
-- @addrtype: IP-address type of the host (/host/address/@addrtype). 
-- @hostname: Hostname (/host/hostnames/hostname/@name).
-- @hostname_type: Hostname type (/host/hostnames/hostname/@type)
-- @osclass_type: Operative system type (/host/os/osclass/@type).
-- @osclass_vendor: Operative system vendor (/host/os/osclass/@vendor).
-- @osclass_osfamily: Operative system family (/host/os/osclass/@osfamily).
-- @osclass_osgen: Operative system generation (/host/os/osclass/@osgen).
-- @osclass_accuracy: Operative system accuracy (/host/os/osclass/@accuracy).
-- @osmatch_name: Operative system name (/host/os/osmatch/@name).
-- @osmatch_accuracy: Operative system name accuracy (/host/os/osmatch/@accuracy).
-- @state: State of the host (/host/status/@state).
-- @state_reason: Reason of state of the host (/host/status/@reason).
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: host_info]\n'

CREATE TABLE host_info(
  report_id TEXT NOT NULL,
  registered TIMESTAMP WITH TIME ZONE  NOT NULL DEFAULT now(),
  scan_jobid BIGINT,
  scan_started TIMESTAMP WITH TIME ZONE,
  scan_finished TIMESTAMP WITH TIME ZONE,
  hostaddr INET NOT NULL,
  addrtype TEXT,
  hostname TEXT [],
  hostname_type TEXT [],
  osclass_type TEXT [],
  osclass_vendor TEXT [],
  osclass_osfamily TEXT [],
  osclass_osgen TEXT [],
  osclass_accuracy INTEGER [],
  osmatch_name TEXT [],
  osmatch_accuracy INTEGER [],
  state TEXT NOT NULL,
  state_reason TEXT
);

ALTER TABLE host_info ADD PRIMARY KEY (report_id,hostaddr);
ALTER TABLE host_info OWNER TO nmap2db_role_rw;

CREATE INDEX host_info_registered_idx ON host_info(registered);
CREATE INDEX host_info_scan_started_idx ON host_info(scan_started);
CREATE INDEX host_info_scan_finished_idx ON host_info(scan_finished);
CREATE INDEX host_info_hostaddr_idx ON host_info(hostaddr);
CREATE INDEX host_info_state_idx ON host_info(state);


-- ------------------------------------------------------------
-- Table: internal_error_log
--
-- @Description: Log table with internal nmap2db errors
--
-- Attributes:
--
-- @id: Log entry ID.
-- @registered: Timestamp when the error was registered.
-- @table_name: Table that generated the error.
-- @operation: Operation that generated the error.
-- @error_message: Error message.
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: internal_error_log]\n'

CREATE TABLE internal_error_log(
  id BIGSERIAL NOT NULL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL,
  error_message TEXT NOT NULL
);

ALTER TABLE internal_error_log ADD PRIMARY KEY (id);
ALTER TABLE internal_error_log OWNER TO nmap2db_role_rw;

CREATE INDEX internal_error_log_registered_idx ON internal_error_log(registered);


-- ------------------------------------------------------------
-- Table: network
--
-- @Description: Information about the networks our system 
--               can scan. If you want to scan a network, it
-- 		 must be defined in this table.
--
-- Attributes:
--
-- @network_addr: Network address. 
-- IPv4 or IPv6 network specification. 
-- Format follows Classless Internet Domain Routing conventions.
--
-- @registered: Timestamp when the network was registered.
-- @last_updated: Timestamp when the network was last updated.
-- @remarks: Remarks about the network.
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: network]\n'

CREATE TABLE network (
  network_addr CIDR NOT NULL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  remarks TEXT
);

ALTER TABLE network ADD PRIMARY KEY (network_addr);
ALTER TABLE network OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Table: network_topology
--
-- @Description:  Information needed by Graphviz about all the 
-- 		  hosts that have been scaned by nmap2db. With this
--		  information and Graphviz we will be able to
--		  generate network topology graphs.
--
-- Attributes:
--
-- @hostaddr: IP-address of a host
-- @hostname: Hostname of host with IP = @hostaddr
-- @adjacent_hostaddr: IP-address of a subsequent host to @hostaddr
-- @adjacent_hostname: Hostname of host with IP = @adjacent_hostaddr 
-- @is_adjacent_a_router: @adjacent_hostaddr is a router [TRUE|FALSE] 
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: network_topology]\n'

CREATE TABLE network_topology(
 hostaddr INET NOT NULL,
 hostname TEXT,
 adjacent_hostaddr INET NOT NULL,
 adjacent_hostname TEXT,
 is_adjacent_a_router BOOLEAN NOT NULL
);

ALTER TABLE network_topology ADD PRIMARY KEY (hostaddr,adjacent_hostaddr);
ALTER TABLE network_topology OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Table: scan_definition
--
-- @Description: Information about the diferent types of scans
-- 		 that can be executed by nmap2db. 
--
-- Attributes:
--
-- @scan_id: Scan definition ID.
-- @args: Arguments used by NMAP to run this scan.
--
--        These arguments "--webxml -oX -" have to be always defined
--	  if we want nmap2db to work properly.
--
-- @remarks: Remarks about this scan definition.
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: scan_definition]\n'

CREATE TABLE scan_definition(
  scan_id TEXT NOT NULL,
  args TEXT NOT NULL,
  remarks TEXT
);

ALTER TABLE scan_definition ADD PRIMARY KEY (scan_id);
ALTER TABLE scan_definition OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Table: scan_job
--
-- @Description: Information about all scan jobs defined in 
-- 		 the nmap2db system.
-- 		 
--		 We can pause the execution of a scan job by
--		 setting the attribute active_status to FALSE.
--
-- Attributes:
--
-- @id: Job ID.
-- @registered: Timestamp when the job was registered.
-- @last_assignment: Timestamp when the job was last assigned to a nmap process.  
-- @last_execution: Timestamp when the job was last executed.
-- @execution_interval: Minimal interval between runs for this job.
-- @active_status: Active status for a job [TRUE|FALSE].
-- @network_addr: Network address. Must be defined in the table network.
-- @scan_id: Scan definition ID for this job. Must be defined in the table scan_definition.
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: scan_job]\n'

CREATE TABLE scan_job(
  id BIGSERIAL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_execution TIMESTAMP WITH TIME ZONE DEFAULT '1970-01-02',
  execution_interval INTERVAL NOT NULL DEFAULT '1 day',
  active_status BOOLEAN NOT NULL DEFAULT 'true',
  network_addr CIDR NOT NULL,
  scan_id TEXT NOT NULL 
);

ALTER TABLE scan_job ADD PRIMARY KEY (network_addr,scan_id);
ALTER TABLE scan_job OWNER TO nmap2db_role_rw;

CREATE UNIQUE INDEX scan_job_id_idx ON scan_job(id);


-- ------------------------------------------------------------
-- Table: scan_job_error_log
--
-- @Description: Log table with executions nmap2db errors 
--
-- Attributes:
--
-- @id: Log entry ID.
-- @registered: Timestamp when the error was registered.
-- @scan_job: Scan job that generated the error.
-- @error_message: Error message.
--
-- ------------------------------------------------------------

\echo '\n# [Creating table: scan_job_error_log]\n'

CREATE TABLE scan_job_error_log(
  id BIGSERIAL,
  registered TIMESTAMP WITH TIME ZONE DEFAULT now(),
  scan_job TEXT,
  error_message TEXT
);

ALTER TABLE scan_job_error_log ADD PRIMARY KEY (id);
ALTER TABLE scan_job_error_log OWNER TO nmap2db_role_rw;

CREATE INDEX scan_job_error_log_registered_idx ON scan_job_error_log(registered);


-- ------------------------------------------------------------
-- Table: scan_report
--
-- @Description: Information about the NMAP scans executed by 
-- 		 nmap2db. All the information in this table is 
-- 		 extracted automatically when saving the XML
-- 		 output of a NMAP scan executed with the 
-- 		 -oX paramater.   
--
-- Attributes:
--
-- @report_id: MD5 value of the XML output of this report
-- @registered: Timestamp when the report was registered.
--
-- @started: Timestamp when the scan was started (/nmaprun/@start)
-- @finished: Timestamp when the scan was finished (/nmaprun/runstats/finished/@time)
-- @elapsed_time: Scan duration (/nmaprun/runstats/finished/@elapsed)
-- @scan_type: Scan type (nmaprun/scaninfo/@type)
-- @scan_protocol: Scan protocol (/nmaprun/scaninfo/@protocol)
-- @scan_numservices: Number of services scanned (/nmaprun/scaninfo/@numservices)
-- @nmap_args: Arguments used by NMAP to run the scan (/nmaprun/@args)
-- @nmap_version: NMAP version used to run the scan (/nmaprun/@version)
-- @xmloutputversion: Version of the XML output (/nmaprun/@xmloutputversion)
-- @host_up: Number of hosts up (/nmaprun/runstats/hosts/@up)
-- @host_down: Number of host down (/nmaprun/runstats/hosts/@down)
-- @host_total: Total number of host scanned (/nmaprun/runstats/hosts/@total)
--
-- @xmlreport: NMAP XML output of the scan 
--
-- ------------------------------------------------------------

\echo '\n# [Creating table:scan_report]\n'

CREATE TABLE scan_report(
  report_id TEXT NOT NULL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  scan_jobid BIGINT,
  started TIMESTAMP WITH TIME ZONE,
  finished TIMESTAMP WITH TIME ZONE,
  elapsed_time NUMERIC,
  scan_type TEXT,
  scan_protocol TEXT,
  scan_numservices INTEGER,
  nmap_args TEXT,
  nmap_version TEXT,
  xmloutputversion TEXT,
  host_up INTEGER,
  host_down INTEGER,
  host_total INTEGER,
  xmlreport XML NOT NULL
);

ALTER TABLE scan_report ADD PRIMARY KEY (report_id);
ALTER TABLE scan_report OWNER TO nmap2db_role_rw;

CREATE INDEX scan_report_registered_idx ON scan_report(registered);
CREATE INDEX scan_report_started_idx ON scan_report(started);
CREATE INDEX scan_report_finished_idx ON scan_report(finished);
CREATE INDEX scan_report_elapsed_time_idx ON scan_report(elapsed_time);


-- ------------------------------------------------------------
-- Table: service_info
--
-- @Description: Information about the services scanned by a scans 
-- 		 executed by nmap2db. All the information in 
-- 		 this table is extracted automatically when saving 
-- 		 the XML output of a NMAP scan executed with the 
-- 		 -oX paramater.     
--
-- Attributes:
--
-- @report_id: MD5 value of the XML output of the report from where 
-- 	       we extract the service information
--
-- @registered: Timestamp when the service information was registered. 

-- @hostaddr: IP-address of the host (/host/address/@addr).
-- @port_protocol: Port protocol (/ports/port/@protocol).
-- @port_id: Port number (/ports/port/@portid).
-- @port_state: Port state (/ports/port/state/@state).
-- @port_state_reason: Reason of state of the port (/ports/port/state/@reason).
-- @service: Service name (/ports/port/service/@name).
-- @service_method: Service method (/ports/port/service/@method).
-- @service_product: Service product (/ports/port/service/@product).
-- @service_product_version: Service product version (/ports/port/service/@version).
-- @service_product_extrainfo: Service product extra information (/ports/port/service/@extrainfo).
--
-- ------------------------------------------------------------

\echo '\n# [Creating table:service_info]\n'

CREATE TABLE service_info(
  report_id TEXT NOT NULL,
  registered TIMESTAMP WITH TIME ZONE  NOT NULL DEFAULT now(),
  scan_jobid BIGINT,
  hostaddr INET  NOT NULL,
  port_protocol TEXT NOT NULL,
  port_id INTEGER NOT NULL,
  port_state TEXT,
  port_state_reason TEXT,
  service TEXT,
  service_method TEXT,
  service_product TEXT,
  service_product_version TEXT,
  service_product_extrainfo TEXT
);

ALTER TABLE service_info ADD PRIMARY KEY (report_id,hostaddr,port_protocol,port_id);
ALTER TABLE service_info OWNER TO nmap2db_role_rw;

CREATE INDEX service_info_registered_idx ON service_info(registered);
CREATE INDEX service_info_hostaddr_idx ON service_info(hostaddr);
CREATE INDEX service_info_port_protocol_idx ON service_info(port_protocol);
CREATE INDEX service_info_port_id_idx ON service_info(port_id);
CREATE INDEX service_info_port_state_idx ON service_info(port_state);
CREATE INDEX service_info_service_idx ON service_info(service);


-- ------------------------------------------------------------
-- Constraints
--
-- ------------------------------------------------------------

\echo '\n# [Creating constraints]\n'

ALTER TABLE scan_job ADD CONSTRAINT scan_id
   FOREIGN KEY (scan_id) REFERENCES scan_definition (scan_id) MATCH FULL;

-- ALTER TABLE scan_job ADD CONSTRAINT network_addr
--   FOREIGN KEY (network_addr) REFERENCES network (network_addr) MATCH FULL;

ALTER TABLE host_info ADD CONSTRAINT report_id
   FOREIGN KEY (report_id) REFERENCES scan_report (report_id) MATCH FULL ON DELETE CASCADE;

ALTER TABLE host_info ADD CONSTRAINT hostaddr 
   FOREIGN KEY (hostaddr) REFERENCES hostaddress (hostaddr) MATCH FULL ON DELETE CASCADE;

ALTER TABLE service_info ADD CONSTRAINT report_id
   FOREIGN KEY (report_id) REFERENCES scan_report (report_id) MATCH FULL ON DELETE CASCADE;

ALTER TABLE service_info ADD CONSTRAINT hostaddr 
   FOREIGN KEY (hostaddr) REFERENCES hostaddress (hostaddr) MATCH FULL ON DELETE CASCADE;

ALTER TABLE scan_report ADD CONSTRAINT scan_jobid
   FOREIGN KEY (scan_jobid) REFERENCES scan_job (id) MATCH FULL ON DELETE CASCADE;

-- ------------------------------------------------------------
-- Function: disable_delete()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function disable_delete]\n'

CREATE OR REPLACE FUNCTION disable_delete() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
    BEGIN
      --
      -- This function can be used by a trigger to disable 
      -- the delete operation in a table.
      --

      RETURN NULL;
    END;
$$;

ALTER FUNCTION disable_delete() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: check_network_inclusion()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function check_network_inclusion]\n'

CREATE OR REPLACE FUNCTION check_network_inclusion() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
 DECLARE   
 included BOOLEAN;
    BEGIN
       --
       -- This function can be used by a trigger to check before insertion if a new network
       -- is already defined in the table network.
       --    
       -- If the new network is already defined in the table network, the insertion gets aborted.
       --

       FOR included IN SELECT NEW.network_addr <<= network_addr from network LOOP

          IF included IS TRUE THEN
	     
	     EXECUTE 'INSERT INTO internal_error_log (table_name, operation, error_message) VALUES ($1,$2,$3)'
             USING TG_TABLE_NAME,
	     	   TG_OP,
		   'This network (' || NEW.network_addr ||') is already defined or included in one of the networks registered in the network table';

	     RAISE 'This network (%) is already defined or included in one of the networks registered in the network table' ,NEW.network_addr;
	     
	     RETURN NULL;
	  END IF;

       END LOOP;

       RETURN NEW;
    END;
$$;

ALTER FUNCTION check_network_inclusion() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: update_timestamp()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function update_last_updated]\n'

CREATE OR REPLACE FUNCTION update_last_updated() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
    BEGIN
       --
       -- This function can be used by a trigger to update the 
       -- attributte last_updated in a table.
       --

       NEW.last_updated := now();
       RETURN NEW;
    END;
$$;

ALTER FUNCTION update_last_updated() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: generate_hostaddr()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function generate_hostaddr]\n'

CREATE OR REPLACE FUNCTION generate_hostaddr() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
    BEGIN
       --
       -- This function can be used by a trigger to update the table
       -- hostadress with all the IPs from a new registered network.
       --

       EXECUTE 'INSERT INTO hostaddress (hostaddr) SELECT expand_network($1)'
       USING NEW.network_addr;	      

       RETURN NULL;
    END;
$$;

ALTER FUNCTION generate_hostaddr() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: remove_hostaddr()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function remove_hostaddr]\n'

CREATE OR REPLACE FUNCTION remove_hostaddr() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
    BEGIN
       --
       -- This function can be used by a trigger to delete from the table
       -- hostadress all the IPs from a deleted network.
       --

       EXECUTE 'DELETE FROM hostaddress 
       	        WHERE hostaddr IN (SELECT expand_network($1))'
       USING OLD.network_addr;

       RETURN NULL;
    END;
$$;

ALTER FUNCTION remove_hostaddr() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: remove_scan_job_network()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function remove_scan_job_network]\n'

CREATE OR REPLACE FUNCTION remove_scan_job_network() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
 DECLARE   
 included BOOLEAN;
    BEGIN
       --
       -- This function can be used by a trigger to delete the scan jobs defined in the table scan_job
       -- that has a network_addr included in the network deleted from the table network.
       --    

       EXECUTE 'DELETE FROM scan_job
               WHERE network_addr <<= $1'
       USING OLD.network_addr;
       RETURN NULL;
    END;
$$;

ALTER FUNCTION remove_scan_job_network() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: update_last_scanned()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function update_last_scanned]\n'

CREATE OR REPLACE FUNCTION update_last_scanned() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
    BEGIN
       --
       -- This function can be used by a trigger to update the 
       -- attributtes last_scanned and total_scans when a hostaddr 
       -- is scanned by nmap2db
       --

       EXECUTE 'UPDATE hostaddress
       	        SET 
		last_scanned = $1,
		total_scans = total_scans + 1
		WHERE hostaddr = $2'
       
       USING NEW.scan_finished,
       	     NEW.hostaddr;
		
       RETURN NULL;
    END;
$$;

ALTER FUNCTION update_last_scanned() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: decrease_total_scans()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function decrease_total_scans]\n'

CREATE OR REPLACE FUNCTION decrease_total_scans() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
    BEGIN
       --
       -- This function can be used by a trigger to decrease the 
       -- attributte total_scans when a hostaddr is deleted from host_info
       --

       EXECUTE 'UPDATE hostaddress
       	        SET 
		total_scans = total_scans - 1
		WHERE hostaddr = $1'
       USING OLD.hostaddr;
		
       RETURN NULL;
    END;
$$;

ALTER FUNCTION decrease_total_scans() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: update_scan_job_last_execution()
--
-- Parameters:
-- @scan_job_id (BIGINT): Scan job ID
--
-- Return: VOID
-- ------------------------------------------------------------

\echo '\n# [Creating function update_scan_job_last_execution]\n'

CREATE OR REPLACE FUNCTION update_scan_job_last_execution(scan_job_id_ BIGINT) RETURNS VOID
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
 BEGIN
  -- This function is used by nmap2db_scan.sh to register
  -- when the last execution of a scan job defined in the table 
  -- scan_job was finnished.
  --
 
  EXECUTE 'UPDATE scan_job SET last_execution = now() WHERE id = $1'
  USING scan_job_id_;

  RETURN;
 END;
$$;

ALTER FUNCTION update_scan_job_last_execution(BIGINT) OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: check_scan_job_network()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function check_scan_job_network]\n'

CREATE OR REPLACE FUNCTION check_scan_job_network() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
 DECLARE   
 included BOOLEAN;
    BEGIN
       --
       -- This function can be used by a trigger to check before insertion if the network
       -- of a new scan job is defined in the table network.
       --    
       -- If the network for the new scan job is not defined in the table network, the insertion gets aborted.
       --

       FOR included IN SELECT NEW.network_addr <<= network_addr FROM network LOOP

          IF included IS TRUE THEN
	     RETURN NEW;
	  END IF;

       END LOOP;
       
       EXECUTE 'INSERT INTO internal_error_log (table_name, operation, error_message) VALUES ($1,$2,$3)'
       USING TG_TABLE_NAME,
	     TG_OP,
	     'This IP/network (' || NEW.network_addr || ') is not defined in the network table';

       RAISE 'This IP/network (%) is not defined in the network table', NEW.network_addr;

       RETURN NULL;
    END;
$$;

ALTER FUNCTION check_scan_job_network() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: extract_report_values()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function extract_report_values]\n'

CREATE OR REPLACE FUNCTION extract_report_values() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
    BEGIN
       --
       -- This function can be used by a trigger to extract information from a XML report
       -- from a NMAP scaning. The information extracted is used to update some attributes
       -- in the table scan_report.
       --	    

       NEW.report_id := md5(NEW.xmlreport::text);
       NEW.started := to_timestamp((xpath('/nmaprun/@start', NEW.xmlreport))[1]::text::integer);
       NEW.finished := to_timestamp((xpath('/nmaprun/runstats/finished/@time', NEW.xmlreport))[1]::text::integer);
       NEW.elapsed_time := (xpath('/nmaprun/runstats/finished/@elapsed', NEW.xmlreport))[1]::text::numeric;
       NEW.scan_type := (xpath('/nmaprun/scaninfo/@type', NEW.xmlreport))[1]::text;
       NEW.scan_protocol := (xpath('/nmaprun/scaninfo/@protocol', NEW.xmlreport))[1]::text;
       NEW.scan_numservices := (xpath('/nmaprun/scaninfo/@numservices', NEW.xmlreport))[1]::text::integer;
       NEW.nmap_args := (xpath('/nmaprun/@args', NEW.xmlreport))[1]::text;
       NEW.nmap_version :=  (xpath('/nmaprun/@version', NEW.xmlreport))[1]::text;
       NEW.xmloutputversion :=  (xpath('/nmaprun/@xmloutputversion', NEW.xmlreport))[1]::text;
       NEW.host_up := (xpath('/nmaprun/runstats/hosts/@up', NEW.xmlreport))[1]::text::integer;
       NEW.host_down := (xpath('/nmaprun/runstats/hosts/@down', NEW.xmlreport))[1]::text::integer;
       NEW.host_total := (xpath('/nmaprun/runstats/hosts/@total', NEW.xmlreport))[1]::text::integer;

       RETURN NEW;
    END;
$$;

ALTER FUNCTION extract_report_values() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: extract_host_and_services_values()
--
-- ------------------------------------------------------------

\echo '\n# [Creating function extract_host_and_services_values]\n'

CREATE OR REPLACE FUNCTION extract_hosts_and_services_values() RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
 DECLARE
  hosts_scanned RECORD;
  services_scanned RECORD;
  traceroute_hops INTEGER;
  loop_ INTEGER;
  check_hostaddr INTEGER;
  hostaddr_ INET;
  hostname_ TEXT;
  adjacent_hostaddr_ INET;
  adjacent_hostname_ TEXT;
  is_adjacent_a_router_ BOOLEAN;		     
  hops XML [];
  
    BEGIN
      --
      -- This function can be used by a trigger to extract information from a XML report
      -- from a NMAP scaning. The information extracted is used to update some attributes
      -- in the tables host_info, service_info and network_topology.
      --
      -- This function is executed everytime a new report is saved in the table scan_report.
      -- If the report delivers traceroute information, the table network_topology gets
      -- updated if necessary.
      --

    -- 
    -- Main loop. We get all the hosts in the report.
    --

    FOR hosts_scanned IN SELECT host_scanned::xml FROM (SELECT unnest(xpath('//host', NEW.xmlreport)) AS host_scanned) AS foo LOOP

    	EXECUTE 'INSERT INTO host_info (report_id,
			     	        scan_jobid,
     				        scan_started,
				        scan_finished,
				        hostaddr,
				        addrtype,
				        hostname,
				        hostname_type,
					osclass_type,
					osclass_vendor,
					osclass_osfamily,
					osclass_osgen,
					osclass_accuracy,
					osmatch_name,
					osmatch_accuracy,
				        state,
				        state_reason)
                 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)'

        USING NEW.report_id,
	      NEW.scan_jobid,
	      to_timestamp((xpath('/host/@starttime', hosts_scanned.host_scanned))[1]::text::integer),
	      to_timestamp((xpath('/host/@endtime', hosts_scanned.host_scanned))[1]::text::integer), 	     
	      (xpath('/host/address/@addr', hosts_scanned.host_scanned))[1]::text::inet,
	      (xpath('/host/address/@addrtype', hosts_scanned.host_scanned))[1]::text,
	      (xpath('/host/hostnames/hostname/@name', hosts_scanned.host_scanned)),
	      (xpath('/host/hostnames/hostname/@type', hosts_scanned.host_scanned)),
	      (xpath('/host/os/osmatch/osclass/@type', hosts_scanned.host_scanned)),
	      (xpath('/host/os/osmatch/osclass/@vendor', hosts_scanned.host_scanned)),
	      (xpath('/host/os/osmatch/osclass/@osfamily', hosts_scanned.host_scanned)),
	      (xpath('/host/os/osmatch/osclass/@osgen', hosts_scanned.host_scanned)),
	      (xpath('/host/os/osmatch/osclass/@accuracy', hosts_scanned.host_scanned))::text[]::integer[],
	      (xpath('/host/os/osmatch/@name', hosts_scanned.host_scanned)),
	      (xpath('/host/os/osmatch/@accuracy', hosts_scanned.host_scanned))::text[]::integer[],
	      (xpath('/host/status/@state', hosts_scanned.host_scanned))[1]::text,
	      (xpath('/host/status/@reason', hosts_scanned.host_scanned))[1]::text;

	 --
	 -- Service loop. We get all the services for a host
	 --

         FOR services_scanned IN SELECT service_scanned::xml FROM (SELECT unnest(xpath('//ports/port',hosts_scanned.host_scanned)) AS service_scanned) AS foo2 LOOP   	


             EXECUTE 'INSERT INTO service_info (report_id,
	     	     	     	  	        scan_jobid,
				                hostaddr,
                                                port_protocol,
				                port_id,
				                port_state,
				                port_state_reason,
				                service,
				                service_method,
				                service_product,
 				                service_product_version,
 				                service_product_extrainfo
				               )
	              VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)'

            USING NEW.report_id,
	    	  NEW.scan_jobid,
		  (xpath('/host/address/@addr', hosts_scanned.host_scanned))[1]::text::inet,
	          (xpath('/port/@protocol', services_scanned.service_scanned))[1]::text,
	          (xpath('/port/@portid', services_scanned.service_scanned))[1]::text::integer,
	          (xpath('/port/state/@state', services_scanned.service_scanned))[1]::text,
	          (xpath('/port/state/@reason', services_scanned.service_scanned))[1]::text,
	          (xpath('/port/service/@name', services_scanned.service_scanned))[1]::text,
	          (xpath('/port/service/@method', services_scanned.service_scanned))[1]::text,
	          (xpath('/port/service/@product', services_scanned.service_scanned))[1]::text,
	          (xpath('/port/service/@version', services_scanned.service_scanned))[1]::text,
	          (xpath('/port/service/@extrainfo', services_scanned.service_scanned))[1]::text;

	  END LOOP;

 	 --
	 -- If the host has status up and traceroute information, the table network_topology gets
      	 -- updated if necessary
	 --

	 IF (xpath('/host/status/@state', hosts_scanned.host_scanned))[1]::text = 'up' THEN

	   traceroute_hops := array_length(xpath('/host/trace/*',hosts_scanned.host_scanned),1);

	   IF traceroute_hops > 1 THEN

	         FOR loop_ IN 1..(traceroute_hops) LOOP
		  hops[loop_]:= (xpath('/host/trace/*',hosts_scanned.host_scanned))[loop_];
		 END LOOP;
	   
	 	 FOR loop_ IN 1..(traceroute_hops-1) LOOP
	     
	          hostaddr_:= unnest(xpath('/hop/@ipaddr',hops[loop_]))::text::inet;
		  hostname_ :=  unnest(xpath('/hop/@host',hops[loop_]))::text;
	     	  adjacent_hostaddr_ :=  unnest(xpath('/hop/@ipaddr',hops[loop_+1]))::text::inet;
		  adjacent_hostname_ :=  unnest(xpath('/hop/@host',hops[loop_+1]))::text;
		  
		  IF loop_ != (traceroute_hops-1) THEN
		    is_adjacent_a_router_ := TRUE;  
		  ELSIF loop_ = (traceroute_hops-1) THEN
		    is_adjacent_a_router_ := FALSE;	  
		  END IF;

	     	  SELECT cnt INTO check_hostaddr FROM (SELECT count(*) AS cnt FROM network_topology WHERE hostaddr = hostaddr_ AND adjacent_hostaddr = adjacent_hostaddr_) AS foo3;

	     	  IF check_hostaddr = 0 THEN	 
		 		    
	     	     EXECUTE 'INSERT INTO network_topology (hostaddr,hostname,adjacent_hostaddr,adjacent_hostname,is_adjacent_a_router) VALUES ($1,$2,$3,$4,$5)'
                     USING hostaddr_, 
		       	   hostname_,
		           adjacent_hostaddr_,
			   adjacent_hostname_,
			   is_adjacent_a_router_;
	          END IF;

	 	 END LOOP;

           END IF;
          END IF;
    END LOOP;
    
    RETURN NULL;
    END;
$$;

ALTER FUNCTION extract_hosts_and_services_values() OWNER TO nmap2db_role_rw;

 
-- ------------------------------------------------------------
-- Function: expand_network()
--
-- Parameters:
-- @network_ (CIDR): Network address. 
-- 	     	     IPv4 or IPv6 network specification. 
-- 		     Format follows Classless Internet Domain 
-- 		     Routing conventions.
--
-- Return: SET of IPs
-- ------------------------------------------------------------

\echo '\n# [Creating function expand_network]\n'

CREATE OR REPLACE FUNCTION expand_network(network_ CIDR) RETURNS SETOF INET 
LANGUAGE plpgsql 
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
 DECLARE
  hostmask INTEGER [];
  network INTEGER [];

  byte_1 INTEGER;	
  byte_2 INTEGER;
  byte_3 INTEGER;
  byte_4 INTEGER;

 BEGIN
  --
  -- This function can be used to generate all the IPs in a network.
  -- It only supports IPv4. IPv6 is in the TODO list. 
  --

  IF family(network_) = 4 THEN

   SELECT INTO hostmask host FROM (SELECT regexp_split_to_array(host(hostmask(network_)),E'\\.')::integer [] AS host) host;
   SELECT INTO network net FROM (SELECT regexp_split_to_array(host(network(network_)),E'\\.')::integer [] AS net) net;

   FOR byte_1 IN 0..hostmask[1] LOOP
      FOR byte_2 IN 0..hostmask[2] LOOP
          FOR byte_3 IN 0..hostmask[3] LOOP

	      -- Do not generate network & broadcast values: 1..hostmask[4]-1

              FOR byte_4 IN 1..hostmask[4]-1 LOOP 
	           RETURN QUERY SELECT (network[1]+byte_1 || '.' ||  network[2]+byte_2 || '.' || network[3]+byte_3 || '.' || network[4]+byte_4)::inet; 
              END LOOP;    
          END LOOP;    
      END LOOP;    
   END LOOP;
  
   --
   -- If the netmask of the network is /32 there is only an IP to return.
   -- 

   IF  hostmask[1] = 0 AND hostmask[2] = 0 AND  hostmask[3] = 0 AND  hostmask[4] = 0 THEN
     RETURN QUERY SELECT (network[1] || '.' ||  network[2] || '.' || network[3] || '.' || network[4])::inet; 
   END IF;

  END IF;
END;
$$;

ALTER FUNCTION expand_network(CIDR) OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: get_next_scan_job()
--
-- Parameters:
--
-- Return: scan job ID
-- ------------------------------------------------------------

\echo '\n# [Creating function get_next_scan_job]\n'

CREATE OR REPLACE FUNCTION get_next_scan_job() RETURNS BIGINT
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  assigned_id BIGINT;
  current_time_ TIMESTAMP WITH TIME ZONE := now();
 BEGIN

 --
 -- This function returns the next scan job that has to be executed for a network. 
 -- It returns the job id with the highest delay according to the attribute execution_interval 
 --

 --
 -- The idea for this function has been gotten from 
 -- https://github.com/ryandotsmith/queue_classic/
 -- 
 -- If we can not get a lock right away for SELECT FOR UPDATE
 -- we abort the select with NOWAIT, wait random()sec. and try again.
 -- With this we try to avoid problems in system with a lot of 
 -- concurrency processes trying to get a job assigned.
 --

  LOOP
    BEGIN
      EXECUTE 'SELECT id'
        || ' FROM scan_job'
        || ' WHERE ($1 - last_execution) >= execution_interval'
        || ' AND active_status IS TRUE'
        || ' ORDER BY ($1 - last_execution) DESC'
        || ' LIMIT 1'
        || ' FOR UPDATE NOWAIT'
      INTO assigned_id
      USING current_time_;
      EXIT;
    EXCEPTION
      WHEN lock_not_available THEN
        -- do nothing. loop again and hope we get a lock
    END;

    PERFORM pg_sleep(random());

  END LOOP;

  EXECUTE 'UPDATE scan_job'
    || ' SET last_execution = now()'
    || ' WHERE id = $1'
    || ' RETURNING id'
  USING assigned_id;

 RETURN assigned_id;

 END;
$$;

ALTER FUNCTION get_next_scan_job() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: get_scan_job_network_addr()
--
-- Parameters:
-- @scan_job_id (BIGINT): Scan job ID
--
-- Return: network_addr for a scan job
-- ------------------------------------------------------------

\echo '\n# [Creating function get_scan_job_network_addr]\n'

CREATE OR REPLACE FUNCTION get_scan_job_network_addr(BIGINT) RETURNS CIDR 
LANGUAGE sql
SECURITY INVOKER
SET search_path = public, pg_temp 
AS $$
 -- 
 -- This function returns the network_addr for a scan job definition.
 --

  SELECT a.network_addr 
  FROM scan_job a 
  WHERE a.id = $1;

$$;

ALTER FUNCTION get_scan_job_network_addr(BIGINT) OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: get_scan_job_args()
--
-- Parameters:
-- @scan_job_id (BIGINT): Scan job ID
--
-- Return: NMAP arguments for a scan job
-- ------------------------------------------------------------

\echo '\n# [Creating function get_scan_job_args]\n'

CREATE OR REPLACE FUNCTION get_scan_job_args(BIGINT) RETURNS TEXT 
LANGUAGE sql
SECURITY INVOKER
SET search_path = public, pg_temp 
AS $$
 --
 -- This function returns the NMAP arguments for a scan job definition.
 --

  SELECT b.args 
  FROM scan_job a 
  INNER JOIN scan_definition b 
  ON a.scan_id = b.scan_id 
  WHERE a.id = $1;

$$;

ALTER FUNCTION get_scan_job_args(BIGINT) OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: get_active_scan_job_networks()
--
-- Parameters:
-- None
--
-- Return: All active network_addr in the scan job table
-- ------------------------------------------------------------

\echo '\n# [Creating function get_active_scan_job_networks]\n'

CREATE OR REPLACE FUNCTION get_active_scan_job_networks() RETURNS SETOF CIDR
LANGUAGE sql
SECURITY INVOKER
SET search_path = public, pg_temp 
AS $$

 -- 
 -- This function returns all active network_addr in the scan job table.
 --

  SELECT DISTINCT network_addr 
  FROM scan_job 
  WHERE active_status IS TRUE 
  ORDER BY network_addr;

$$;

ALTER FUNCTION get_active_scan_job_networks() OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: save_scan_report()
--
-- Parameters:
-- @xmlreport (XML): XML report from a NMAP scan
--
-- Return: Report ID for the scan report saved in the database
-- ------------------------------------------------------------

\echo '\n# [Creating function save_scan_report]\n'

CREATE OR REPLACE FUNCTION save_scan_report(scan_jobid BIGINT, xmlreport XML) RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp 
AS $$
BEGIN
 --
 -- This function saves in the database the XML report from a NMAP scan 
 --

  EXECUTE 'INSERT INTO scan_report (scan_jobid,xmlreport) VALUES ($1,$2)'
  USING scan_jobid,
  	lower(xmlreport::text)::xml;

  RETURN;
END;
$$;

ALTER FUNCTION save_scan_report(BIGINT,XML) OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: generate_topology_dot_output()
--
-- Parameters:
-- @mode (TEXT): Output mode [normal|full]
--
-- Return: DOT output for generating a network topology graph with Graphviz.
-- ------------------------------------------------------------

\echo '\n# [Creating function generate_topology_dot_output]\n'

CREATE OR REPLACE FUNCTION generate_topology_dot_output(mode TEXT) RETURNS TEXT 
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp 
AS $$
DECLARE
 network_topology RECORD;
 return_value TEXT := '';
BEGIN
  --
  -- This function generates the DOT output necessary to generate a 
  -- network topology graph from the data saved in the table network_topology.
  -- 
  -- Mode = normal generates a graph with only the nodes that are routers.
  -- Mode = full generates a graph with all the nodes (routers and end nodes)
  --
  -- The output generated can be sent with a unix pipe (|) to this command to generate
  -- a PNG file named network_topology.png: "dot -Tpng -o network_topology.png"
  --

  return_value := return_value || E'digraph network_topology {\n\n';
	
  IF lower(mode) = 'normal' THEN

   FOR network_topology IN (

    SELECT '"' ||                                                                                                  
          CASE WHEN hostname IS NULL THEN hostaddr::text 
               WHEN hostname IS NOT NULL THEN hostname 
          END 
          || '" -> "' ||
          CASE WHEN adjacent_hostname IS NULL THEN adjacent_hostaddr::text 
          WHEN adjacent_hostname IS NOT NULL THEN adjacent_hostname 
          END
	  || '";' 
	  AS dot_output
    FROM network_topology
    WHERE is_adjacent_a_router IS TRUE

    )LOOP

    return_value := return_value || '   ' || network_topology.dot_output || E'\n';

    END LOOP;

   ELSIF lower(mode) = 'full' THEN
     
     FOR network_topology IN (

    SELECT '"' ||                                                                                                  
          CASE WHEN hostname IS NULL THEN hostaddr::text 
               WHEN hostname IS NOT NULL THEN hostname 
          END 
          || '" -> "' ||
          CASE WHEN adjacent_hostname IS NULL THEN adjacent_hostaddr::text 
          WHEN adjacent_hostname IS NOT NULL THEN adjacent_hostname 
          END
	  || '";' 
	  AS dot_output
    FROM network_topology

    )LOOP

    return_value := return_value || '   ' || network_topology.dot_output || E'\n';

    END LOOP;

   END IF;

  return_value := return_value || E'}\n';

  RETURN return_value;
END;
$$;

ALTER FUNCTION generate_topology_dot_output(TEXT) OWNER TO nmap2db_role_rw;

-- ------------------------------------------------------------
-- Function: xml_host_info()
--
-- Parameters:
--
-- ------------------------------------------------------------

\echo '\n# [Creating function xml_host_info]\n'

CREATE OR REPLACE FUNCTION xml_host_info(INET) RETURNS XML AS
'
  SELECT xmlroot(xmlconcat(''<?xml-stylesheet href="host_info.xsl" type="text/xsl"?>'', xmlelement(name host_info,
  	            xmlelement(name scan,
  	            xmlelement(name scan_id,a.report_id),
		    xmlelement(name scan_args,b.nmap_args),
  	            xmlelement(name scan_registered,date_trunc(''second'',a.registered)),
		    xmlelement(name scan_started,date_trunc(''second'',a.scan_started)),
		    xmlelement(name scan_finished,date_trunc(''second'',a.scan_finished))
		    ),
		    xmlelement(name host,
		    xmlelement(name hostaddr,a.hostaddr),
		    xmlelement(name addrtype,a.addrtype),
		    xmlelement(name hostname,array_to_string(a.hostname,'','')),
		    xmlelement(name hostname_type,array_to_string(a.hostname_type,'','')),
		    xmlelement(name last_scanned,date_trunc(''second'',c.last_scanned)),
		    xmlelement(name total_scans,c.total_scans),
		    xmlelement(name state, a.state),
		    xmlelement(name state_reason, a.state_reason),

		    xmlelement(name os,		
		    xmlelement(name osclass_type,a.osclass_type[1]),
		    xmlelement(name osclass_vendor,a.osclass_vendor[1]),
		    xmlelement(name osclass_osfamily,a.osclass_osfamily[1]),
		    xmlelement(name osclass_osgen,a.osclass_osgen[1]),
		    xmlelement(name osclass_accuracy,a.osclass_accuracy[1]),
		    xmlelement(name osmatch_name,a.osmatch_name[1]),
		    xmlelement(name osmatch_accuracy,a.osmatch_accuracy[1]))
		    
                    )
 		    )),version ''1.0'', standalone no)
  FROM host_info a
  FULL JOIN scan_report b ON a.report_id = b.report_id
  FULL JOIN hostaddress c ON a.hostaddr = c.hostaddr
  WHERE a.hostaddr = $1
  ORDER BY a.scan_finished DESC;
'
LANGUAGE sql;


-- ------------------------------------------------------------
-- Triggers: table network
--
-- ------------------------------------------------------------

\echo '\n# [Creating triggers table: network]\n'

CREATE TRIGGER check_network_inclusion
BEFORE INSERT ON network
    FOR EACH ROW EXECUTE PROCEDURE check_network_inclusion();

CREATE TRIGGER generate_hostaddr
AFTER INSERT ON network
    FOR EACH ROW EXECUTE PROCEDURE generate_hostaddr();

CREATE TRIGGER remove_hostaddr
AFTER DELETE ON network
    FOR EACH ROW EXECUTE PROCEDURE remove_hostaddr();

CREATE TRIGGER update_last_updated
BEFORE UPDATE ON network
    FOR EACH ROW EXECUTE PROCEDURE update_last_updated();


-- ------------------------------------------------------------
-- Triggers: table scan_report
--
-- ------------------------------------------------------------

\echo '\n# [Creating triggers table: scan_report]\n'

CREATE TRIGGER extract_report_values
BEFORE INSERT ON scan_report
    FOR EACH ROW EXECUTE PROCEDURE extract_report_values();

CREATE TRIGGER extract_hosts_and_services_values
AFTER INSERT ON scan_report
   FOR EACH ROW EXECUTE PROCEDURE extract_hosts_and_services_values();


-- ------------------------------------------------------------
-- Triggers: table host_info
--
-- ------------------------------------------------------------

\echo '\n# [Creating triggers table: host_info]\n'

CREATE TRIGGER update_last_scanned
AFTER INSERT ON host_info
    FOR EACH ROW EXECUTE PROCEDURE update_last_scanned();

CREATE TRIGGER decrease_total_scans
AFTER DELETE ON host_info
    FOR EACH ROW EXECUTE PROCEDURE decrease_total_scans();



-- ------------------------------------------------------------
-- Triggers: table scan_job
--
-- ------------------------------------------------------------

\echo '\n# [Creating triggers table: scan_job]\n'

CREATE TRIGGER check_scan_job_network
BEFORE INSERT OR UPDATE ON scan_job
    FOR EACH ROW EXECUTE PROCEDURE check_scan_job_network();

CREATE TRIGGER remove_network
AFTER DELETE ON network
    FOR EACH ROW EXECUTE PROCEDURE remove_scan_job_network();


-- ------------------------------------------------------------
-- Privileges
--
-- ------------------------------------------------------------

REVOKE ALL ON DATABASE nmap2db FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

REVOKE ALL ON DATABASE nmap2db FROM nmap2db_role_rw;
REVOKE ALL ON SCHEMA public FROM nmap2db_role_rw;

REVOKE ALL ON DATABASE nmap2db FROM nmap2db_role_ro;
REVOKE ALL ON SCHEMA public FROM nmap2db_role_ro;

GRANT ALL ON DATABASE nmap2db TO nmap2db_role_rw;
GRANT ALL ON SCHEMA public TO nmap2db_role_rw;

GRANT CONNECT ON DATABASE nmap2db TO nmap2db_role_ro;
GRANT USAGE ON SCHEMA public TO nmap2db_role_ro;

GRANT SELECT ON all tables in schema public to nmap2db_role_ro;
GRANT SELECT ON all sequences in schema public to nmap2db_role_ro;


-- ------------------------------------------------------------
-- Initialization values
--
-- ------------------------------------------------------------

\echo '\n# [Initialize default values]\n'

--
-- Scan definitions
--

INSERT INTO scan_definition (scan_id,args,remarks) VALUES ('sn-traceroute','--webxml -oX - -sn --traceroute','No port scan + traceroute');
INSERT INTO scan_definition (scan_id,args,remarks) VALUES ('sS-sV-O','--webxml -oX - -sS -sV -O','TCP SYN scan + Version detection + OS detection');
INSERT INTO scan_definition (scan_id,args,remarks) VALUES ('t4-sU-p','--webxml -oX - -T4 -sU -p 53,66,67,68,69,111,113,123,135,137-139,150,161,162,445,500,514,520,631,640,1434,1900,4045,4500,31337,32768,49152','UDP scan for commom UDP ports');
INSERT INTO scan_definition (scan_id,args,remarks) VALUES ('sS-sV','--webxml -oX - -sS -sV','TCP SYN scan + Version detection');



--
-- CLI funtions
--

-- ------------------------------------------------------------
-- Function: register_network()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION register_network(CIDR,TEXT) RETURNS VOID
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  network_addr_ ALIAS FOR $1;
  remarks_ ALIAS FOR $2;  

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT;
 BEGIN

   IF network_addr_ IS NULL THEN
      RAISE EXCEPTION 'Network value has not been defined';
   END IF;

   EXECUTE 'INSERT INTO network (network_addr,remarks) VALUES ($1,$2)'
   USING network_addr_,
         remarks_;         

 EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------', v_msg, v_detail, v_context;
  
END;
$$;

ALTER FUNCTION register_network(CIDR,TEXT) OWNER TO nmap2db_role_rw;


-- ------------------------------------------------------------
-- Function: register_job_scan()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION register_scan_job(CIDR,TEXT,INTERVAL,BOOLEAN) RETURNS VOID
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  network_addr_ ALIAS FOR $1;
  scan_id_ ALIAS FOR $2;
  execution_interval_ ALIAS FOR $3;
  active_status_ ALIAS FOR $4; 

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT;
 BEGIN

   IF network_addr_ IS NULL THEN
      RAISE EXCEPTION 'Network value has not been defined';
   END IF;

   EXECUTE 'INSERT INTO scan_job (network_addr,scan_id,execution_interval,active_status) VALUES ($1,$2,$3,$4)'
   USING network_addr_,
         scan_id_,
	 execution_interval_,
	 active_status_;         

 EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------', v_msg, v_detail, v_context;
  
END;
$$;

ALTER FUNCTION register_scan_job(CIDR,TEXT,INTERVAL,BOOLEAN) OWNER TO nmap2db_role_rw;


--
-- Views
--

CREATE OR REPLACE VIEW show_network_definitions AS
SELECT network_addr AS "Network",
       remarks AS "Remarks"
FROM network
ORDER BY network_addr;

ALTER VIEW show_network_definitions OWNER TO nmap2db_role_rw;

CREATE OR REPLACE VIEW show_scan_definitions AS
SELECT scan_id AS "ScanID",
       remarks "Remarks",
       args "Arguments"
FROM scan_definition
ORDER BY scan_id;

ALTER VIEW show_scan_definitions OWNER TO nmap2db_role_rw;

CREATE OR REPLACE VIEW show_scan_jobs AS
SELECT id AS "ID",
       last_execution AS "Last execution",
       network_addr AS "Network",
       scan_id AS "ScanID",
       execution_interval AS "Interval",
       CASE 
        WHEN active_status IS TRUE THEN 'Active'
        WHEN active_status IS FALSE THEN 'Stopped'
       END AS "Status"
FROM scan_job
ORDER BY network_addr,scan_id,execution_interval,"Status";

ALTER VIEW show_scan_jobs OWNER TO nmap2db_role_rw;


CREATE OR REPLACE VIEW show_host_reports AS
SELECT a.report_id AS "ReportID",
       c.scan_id AS "ScanID",
       a.registered AS "Registered",
       b.elapsed_time AS "Duration",
       a.hostaddr AS "IPaddress",
       array_to_string(a.hostname,' ') AS "Hostname",
       a.state AS "State"
FROM host_info a
JOIN scan_report b ON a.report_id = b.report_id
JOIN scan_job c ON b.scan_jobid = c.id;

ALTER VIEW show_host_reports OWNER TO nmap2db_role_rw;

CREATE OR REPLACE VIEW show_host_details AS
SELECT a.report_id AS "ReportID",
       a.registered AS "Registered",
       b.scan_id AS "ScanID",
       c.network_addr AS "Network",
       c.remarks AS "Network info",
       a.hostaddr AS "IPaddress",
       a.addrtype AS "Addrtype",
       array_to_string(a.hostname,',','*') AS "Hostname",
       array_to_string(a.hostname_type,',','*') AS "Hostname type",
       array_to_string(a.osclass_type[1:2],',','*') AS "OStype",
       array_to_string(a.osclass_vendor[1:2],',','*') AS "OSvendor",
       array_to_string(a.osclass_osfamily[1:2],',','*') AS "OSfamily",
       array_to_string(a.osclass_osgen[1:2],',','*') AS "OSgen",
       array_to_string(a.osmatch_name[1:2],',','*') AS "OSname",
       a.state AS "State",
       a.state_reason AS "State reason"
FROM host_info a
JOIN scan_job b ON a.scan_jobid = b.id
JOIN network c ON c.network_addr >>= a.hostaddr;

ALTER VIEW show_host_details OWNER TO nmap2db_role_rw;

CREATE OR REPLACE VIEW show_services_details AS
SELECT port_protocol AS "Prot",
       port_id AS "Port",
       port_state AS "State",
       port_state_reason AS "Reason",
       service AS "Service",
       service_method AS "Method",
       service_product AS "Product",
       service_product_version AS "Prod.ver",
       service_product_extrainfo As "Prod.info",
       report_id
FROM service_info 
ORDER BY port_protocol,port_id;

ALTER VIEW show_services_details OWNER TO nmap2db_role_rw;

CREATE OR REPLACE VIEW show_host_without_hostname AS
WITH host_list AS(
SELECT registered,	       
       hostaddr,
       hostname,
       state 
FROM host_info 
WHERE hostname = '{}'
ORDER BY registered DESC)
SELECT DISTINCT ON (hostaddr)
       registered AS "Last registration",
       hostaddr AS "IPaddress",
       hostname AS "Hostname",
       state As "State"
FROM host_list
ORDER BY hostaddr;

ALTER VIEW show_host_without_hostname OWNER TO nmap2db_role_rw;

CREATE OR REPLACE VIEW show_ports AS
SELECT registered,
       hostaddr::cidr AS "IPaddress",
       port_id AS "Port",
       port_protocol AS "Prot",
       port_state AS "State",
       service AS "Service",
       service_product AS "Product",
       service_product_version AS "Prod.ver",
       left(service_product_extrainfo,50) AS "Prod.info"
FROM service_info
ORDER BY port_id,port_protocol,hostaddr;

ALTER VIEW show_ports OWNER TO nmap2db_role_rw;



COMMIT;
