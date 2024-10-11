CREATE APPLICATION ROLE IF NOT EXISTS app_user;

CREATE SCHEMA IF NOT EXISTS core;

GRANT USAGE ON SCHEMA core TO APPLICATION ROLE app_user;

CREATE OR ALTER VERSIONED SCHEMA v1;

GRANT USAGE ON SCHEMA v1 TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE v1.start_app(privileges array) RETURNS string LANGUAGE sql AS $$
    BEGIN

        LET pool_name := 'SFN_COMPUTE_POOL';
        LET warehouse_name := 'SFN_WAREHOUSE';

        CREATE OR REPLACE WAREHOUSE IDENTIFIER(:warehouse_name)
        WITH WAREHOUSE_SIZE='X-SMALL';

        GRANT USAGE ON WAREHOUSE IDENTIFIER(:warehouse_name) TO APPLICATION ROLE app_user;

        CREATE COMPUTE POOL IF NOT EXISTS  IDENTIFIER(:pool_name)
        MIN_NODES = 1
        MAX_NODES = 2
        INSTANCE_FAMILY = CPU_X64_L
        AUTO_RESUME = true;

        GRANT USAGE ON COMPUTE POOL IDENTIFIER(:pool_name) TO APPLICATION ROLE app_user;

-- ADD CREATE SERVICE CODE BELOW THIS LINE #CREATE_SERVICE
        CREATE SERVICE IF NOT EXISTS core.snowchat IN COMPUTE POOL identifier(:pool_name) FROM SPEC='/snowchat.yaml';

-- ADD GRANT SERVICE CODE BELOW THIS LINE #GRANT_SERVICE
        GRANT SERVICE ROLE core.snowchat!sfn_service_role to APPLICATION ROLE app_user;

    RETURN 'Service started. Check status, and when ready, get URL';
    END;
$$;

GRANT USAGE ON PROCEDURE v1.start_app (array) TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE core.stop_app() RETURNS string LANGUAGE sql AS $$
    BEGIN
        LET pool_name := 'SFN_COMPUTE_POOL';
        LET warehouse_name := 'SFN_WAREHOUSE';

-- ADD DROP SERVICE CODE BELOW THIS LINE #DROP_SERVICE
        DROP SERVICE IF EXISTS core.snowchat;

        DROP COMPUTE POOL IF EXISTS IDENTIFIER(:pool_name);
        DROP WAREHOUSE IF EXISTS IDENTIFIER(:warehouse_name);
    RETURN 'Service stopped';
    END
$$;

GRANT USAGE ON PROCEDURE core.stop_app () TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE core.app_url() RETURNS string LANGUAGE sql AS $$
    DECLARE
        ingress_url VARCHAR;
    BEGIN
        SHOW ENDPOINTS IN SERVICE core.nginx;
        SELECT "ingress_url" INTO :ingress_url FROM TABLE (RESULT_SCAN (LAST_QUERY_ID())) LIMIT 1;
        RETURN ingress_url;
    END
$$;

GRANT USAGE ON PROCEDURE core.app_url () TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE core.get_logs(service_name_identifier VARCHAR) RETURNS string LANGUAGE SQL AS $$
    DECLARE
        log_result VARCHAR;
    BEGIN
    SELECT LISTAGG(value, '\n') WITHIN GROUP (ORDER BY seq) INTO :log_result
        FROM TABLE(
            SPLIT_TO_TABLE(SYSTEM$GET_SERVICE_LOGS('core.' || :service_name_identifier, 0, :service_name_identifier), '\n')
        );
    RETURN log_result;
    END
$$;

GRANT USAGE ON PROCEDURE core.get_logs (VARCHAR) TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE core.list_services() RETURNS TABLE() LANGUAGE SQL EXECUTE AS OWNER AS $$
    DECLARE
        res RESULTSET DEFAULT (SHOW SERVICES);
    BEGIN
        RETURN TABLE(res);
    END;
$$;

GRANT USAGE ON PROCEDURE core.list_services () TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE core.service_status(service_name_identifier VARCHAR) RETURNS VARCHAR LANGUAGE SQL EXECUTE AS OWNER AS $$
    DECLARE
            service_status VARCHAR;
    BEGIN
            CALL SYSTEM$GET_SERVICE_STATUS('core.' || :service_name_identifier) INTO :service_status;
            RETURN PARSE_JSON(:service_status)[0]['status']::VARCHAR;
    END;
$$;

GRANT USAGE ON PROCEDURE core.service_status (VARCHAR) TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE v1.GET_CONFIGURATION_FOR_REFERENCE(ref_name STRING) RETURNS STRING LANGUAGE SQL AS $$
    BEGIN
        CASE (ref_name)
            WHEN 'CONSUMER_EXTERNAL_ACCESS' THEN
                RETURN '{
                    "type": "CONFIGURATION",
                    "payload": {
                        "host_ports": [
                            "0.0.0.0:80",
                            "0.0.0.0:443",
                            "api.openai.com:443",
                            "smtp.gmail.com",
                            "app-testing.stepfunction.ai:443"
                        ],
                        "allowed_secrets": "NONE",
                        "secret_references": []
                    }
                }';
            ELSE
                RETURN '{}';
        END CASE;
    END;
    $$;

GRANT USAGE ON PROCEDURE v1.GET_CONFIGURATION_FOR_REFERENCE (STRING) TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE v1.register_reference(ref_name VARCHAR, operation VARCHAR, ref_or_alias VARCHAR) RETURNS VARCHAR LANGUAGE sql AS $$
    DECLARE
        ingress_url VARCHAR;
    BEGIN
        CASE (operation)
            WHEN 'ADD' THEN
                SELECT SYSTEM$SET_REFERENCE(:ref_name, :ref_or_alias);
            WHEN 'REMOVE' THEN
                SELECT SYSTEM$REMOVE_REFERENCE(:ref_name, :ref_or_alias);
            WHEN 'CLEAR' THEN
                SELECT SYSTEM$REMOVE_ALL_REFERENCES(:ref_name);
            ELSE
                RETURN 'unknown operation: ' || operation;
        END CASE;
        RETURN NULL;
    END
$$;

GRANT USAGE ON PROCEDURE v1.register_reference (VARCHAR, VARCHAR, VARCHAR) TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE v1.init()
    RETURNS STRING
    LANGUAGE SQL
    EXECUTE AS OWNER
    AS
    $$
    BEGIN

-- ADD ALTER SERVICE CODE BELOW THIS LINE #ALTER_SERVICE
        ALTER SERVICE IF EXISTS core.snowchat FROM SPECIFICATION_FILE='/snowchat.yaml';

        RETURN 'init complete';
    END $$;

GRANT USAGE ON PROCEDURE v1.init () TO APPLICATION ROLE app_user;