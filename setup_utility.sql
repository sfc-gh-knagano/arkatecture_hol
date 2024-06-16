-- create utility DB

--line 21 need number of participants & line 22 needs password set
--Run 69 and above
create or replace database utility;

-- create a SP to loop queries for N users
-- it replaces the placeholder XXX with N in the supplied query
create or replace procedure utility.public.loopquery (QRY STRING, N FLOAT)
  returns float
  language javascript
  strict
as
$$
  for (i = 0; i <= N; i++) {
    snowflake.execute({sqlText: QRY.replace(/XXX/g, i)});
  }
  return i-1;
$$;

-- Set up the HOL environment for the first time
set num_users = 3; --> adjust number of attendees here
set lab_pwd = 'XXXXXX'; --> enter an attendee password here

-- set up the roles
create or replace role hol_parent comment = "HOL parent role";
use role accountadmin;
grant role hol_parent to role accountadmin;
call utility.public.loopquery('create or replace role roleXXX comment = "HOLXXX User Role";', $num_users);

-- Create Cortex role
CREATE or replace ROLE cortex_user_role;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE cortex_user_role;

-- set up the users
call utility.public.loopquery('create or replace user userXXX default_role=roleXXX password="' || $lab_pwd || '";', $num_users);
call utility.public.loopquery('grant role roleXXX to user userXXX;', $num_users);
call utility.public.loopquery('grant role roleXXX to role hol_parent;', $num_users);
call utility.public.loopquery('grant role roleXXX to role accountadmin;', $num_users);

-- grant account permissions
grant create warehouse on account to role hol_parent;

-----setup warehouse didn't run bc it doesn't exist
--grant usage on warehouse setup_wh to role hol_parent;

-- set up the warehouses and grant permissions
call utility.public.loopquery('create or replace warehouse whXXX warehouse_size = \'xsmall\' AUTO_SUSPEND = 300;', $num_users);
call utility.public.loopquery('grant all on warehouse whXXX to role roleXXX;', $num_users);

-- set up the schemas and grant permissions
call utility.public.loopquery('create or replace schema HOL.schemaXXX clone HOL.PUBLIC;', $num_users);
call utility.public.loopquery('grant usage, modify on database HOL to role roleXXX;', $num_users);
call utility.public.loopquery('grant usage on schema HOL.PUBLIC to role roleXXX;', $num_users);
call utility.public.loopquery('grant ownership on schema HOL.schemaXXX to role roleXXX;', $num_users);
call utility.public.loopquery('grant usage, modify on future schemas in database HOL to role roleXXX;', $num_users);
call utility.public.loopquery('grant all on all tables in schema HOL.schemaXXX to role roleXXX;', $num_users);
call utility.public.loopquery('grant all on all views in schema hol.schemaXXX to role roleXXX;', $num_users);
call utility.public.loopquery('grant all on future views in schema hol.schemaXXX to role roleXXX;', $num_users);
call utility.public.loopquery('GRANT SELECT ON VIEW hol.schemaXXX.sales_forecast_input TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT usage ON schema hol.schemaXXX TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT create stage ON schema hol.schemaXXX TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT usage ON warehouse whXXX TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT ROLE cortex_user_role TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT CREATE STREAMLIT ON SCHEMA hol.schemaXXX TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT CREATE STAGE ON SCHEMA hol.schemaXXX TO ROLE roleXXX', $num_users);

-- Create a Snowflake Managed stage and load all pdfs for Cortex LLM Simple Rag Example
create or replace stage hol.public.pdf;
-- Add pdfs to the newly created stage
call utility.public.loopquery('GRANT read on stage HOL.PUBLIC.PDF to role roleXXX;', $num_users);
call utility.public.loopquery('grant all on stage HOL.PUBLIC.pdf to role roleXXX;', $num_users);

-- if using Snowflake Notebooks, ensure you run the following:
call utility.public.loopquery('GRANT create notebook ON schema hol.schemaXXX TO ROLE roleXXX', $num_users);
call utility.public.loopquery('grant create notebook ON schema hol.schemaXXX TO ROLE accountadmin', $num_users);

-- validate setup is correct this will take a little while to update check at another time
SELECT DISTINCT NAME, LOGIN_NAME, DISPLAY_NAME, DEFAULT_ROLE FROM SNOWFLAKE.ACCOUNT_USAGE.USERS WHERE NAME LIKE 'user%' ORDER BY NAME ASC;

SELECT WAREHOUSE_NAME, USER_NAME FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_EVENTS_HISTORY WHERE WAREHOUSE_NAME LIKE 'WH%' ORDER BY WAREHOUSE_NAME ASC;