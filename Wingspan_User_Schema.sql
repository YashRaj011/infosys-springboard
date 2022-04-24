-------------- ENUM CREATION START --------------
DROP TYPE IF EXISTS imported_source_names;
CREATE TYPE imported_source_names AS ENUM
(
  'DEVELOPER',
  'AUTO_INSERT_VIA_API',
  'PID_CREATE_API',
  'INFOSYS_USER_DUMP',
  'TEST_USER',
  'REQUESTED_USER'
);
--------------- ENUM CREATION END ---------------

-- Meta data table for root_org and orgs
DROP TABLE IF EXISTS org_details;
CREATE TABLE org_details
(
  id SERIAL,
  root_org TEXT,
  org TEXT,
  domain_name TEXT,
  auto_save_email_prefix TEXT,
  auto_save_email_suffix TEXT,
  UNIQUE(root_org, org, domain_name)
);

-- Sample Insert Query
INSERT INTO org_details
  (root_org, org, domain_name, auto_save_email_prefix, auto_save_email_suffix)
values
  ('Infosys', 'Infosys Ltd', 'lex.infosysapps.com', '', '@ad.infosys.com');


-- Creating the user TABLE
DROP TABLE if exists wingspan_user;
CREATE TABLE wingspan_user
(
  wid uuid DEFAULT uuid_generate_v4(),
  root_org TEXT,
  org TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  account_expiry_date DATE,
  kid uuid UNIQUE,
  imported_source_name imported_source_names,
  source_id TEXT,
  username TEXT,
  first_name TEXT,
  last_name TEXT,
  middle_name TEXT,
  known_as TEXT,
  salutation TEXT,
  father_name TEXT,
  mother_name TEXT,
  email TEXT,
  alternate_email TEXT,
  gender TEXT,
  dob DATE,
  race TEXT,
  person_identification_id TEXT,
  user_type TEXT,
  languages_known TEXT[],
  preferred_language TEXT,
  source_profile_picture TEXT,
  residence_address_line1 TEXT,
  residence_address_line2 TEXT,
  residence_city TEXT,
  residence_zipcode TEXT;
  residence_district TEXT;
  residence_state TEXT,
  residence_country TEXT,
  contact_phone_number_office TEXT,
  contact_phone_number_home TEXT,
  contact_phone_number_personal TEXT,
  employment_status TEXT,
  contract_type TEXT,
  job_title TEXT,
  job_role TEXT,
  job_start_date DATE;
  job_end_date DATE;
  department_name TEXT,
  sub_department_name TEXT,
  unit_name TEXT,
  user_properties JSONB,
  organization_location_address_line1 TEXT,
  organization_location_address_line2 TEXT,
  organization_location_city TEXT,
  organization_location_zipcode TEXT;
  organization_location_district TEXT;
  organization_location_state TEXT,
  organization_location_country TEXT,
  json_unmapped_fields JSONB,
  source_data JSONB,
  keycloak_created BOOLEAN NOT NULL DEFAULT false,
  welcome_mail_sent BOOLEAN NOT NULL DEFAULT false,
  is_test_account BOOLEAN NOT NULL DEFAULT false,
  is_purged BOOLEAN NOT NULL DEFAULT false,
  external_data jsonb NOT NULL DEFAULT '{}',
  tags TEXT[],
  checksum TEXT,
  user_search TSVECTOR,
  time_inserted TIMESTAMP DEFAULT NOW(),
  time_first_login TIMESTAMP,
  time_updated TIMESTAMP,
  time_last_active TIMESTAMP,
  inserted_by TEXT,
  updated_by TEXT,
  CONSTRAINT wingspan_user_pkey PRIMARY KEY(wid),
  CONSTRAINT wingspan_user_kid_key UNIQUE(kid),
  CONSTRAINT wingspan_user_email_key UNIQUE (root_org, email),
  CONSTRAINT wingspan_root_org_source_id_uniq UNIQUE (root_org, source_id),
  CONSTRAINT wingspan_root_org_username_uniq UNIQUE (root_org, username)
);

-- Create index on wingspan_user --
CREATE INDEX wingspan_user_search_gin ON wingspan_user USING GIN (user_search);

-- Create index on checksum
CREATE INDEX user_checksum ON wingspan_user(checksum);

-- Create triggers on wingspan_user --
CREATE OR REPLACE FUNCTION update_date_updated_column() 
RETURNS TRIGGER AS $$
BEGIN
    NEW.time_updated = now();
    RETURN NEW; 
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trgr_date_update on wingspan_user;
CREATE TRIGGER trgr_date_update
  BEFORE UPDATE OR INSERT
  ON wingspan_user 
  FOR EACH ROW 
EXECUTE PROCEDURE update_date_updated_column();

-- Trigger function to prepare a user_search vector from wingspan_user meta --
CREATE OR REPLACE FUNCTION update_wingspan_user_search() RETURNS TRIGGER AS $$
BEGIN
  NEW.user_search :=
    setweight(to_tsvector('simple', coalesce(NEW.source_id,'')), 'A') ||
    setweight(to_tsvector('simple', regexp_replace(split_part(coalesce(NEW.email,NEW.alternate_email,''),'@',1),'[^a-zA-Z0-9]',' ','g')), 'A') ||
    setweight(to_tsvector('simple', coalesce(NEW.first_name,'')), 'B') ||
    setweight(to_tsvector('simple', coalesce(NEW.last_name,'')), 'B') ||
    setweight(to_tsvector('simple', coalesce(NEW.email,'')), 'B') ||
    setweight(to_tsvector('simple', coalesce(NEW.unit_name,'')), 'C')||
    setweight(to_tsvector('simple', coalesce(NEW.department_name,'')), 'C') ||
    setweight(to_tsvector('simple', regexp_replace(split_part(coalesce(NEW.email,NEW.alternate_email,''),'@',2),'[^a-zA-Z0-9]',' ','g')), 'D');
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- Creating trigger to populate user_search on insert or update of wingspan_user
DROP TRIGGER wingspan_user_search ON wingspan_user;

CREATE TRIGGER wingspan_user_search BEFORE INSERT OR UPDATE
ON wingspan_user FOR EACH ROW EXECUTE PROCEDURE update_wingspan_user_search();

-- Create user preferences table
DROP TABLE IF EXISTS user_preferences;
CREATE TABLE user_preferences(
  root_org TEXT,
  org TEXT,
  user_id UUID,
  preferences_data JSONB,
  time_inserted TIMESTAMP DEFAULT NOW(),
  time_updated TIMESTAMP,
  CONSTRAINT user_preferences_pkey PRIMARY KEY(user_id),
);

-- Create trigger to update time updated --
CREATE OR REPLACE FUNCTION update_preferences_time_updated() RETURNS TRIGGER AS $trgr_preferences_time_update$
BEGIN
    NEW.time_updated = now();
    RETURN NEW;
END;
$trgr_preferences_time_update$ LANGUAGE plpgsql;

CREATE TRIGGER trgr_preferences_time_update
BEFORE INSERT OR UPDATE ON user_preferences FOR EACH ROW
EXECUTE PROCEDURE update_preferences_time_updated();

-- Create dealer table --
DROP TABLE IF EXISTS dealer;
CREATE TABLE dealer(
  root_org TEXT NOT NULL,
  org TEXT NOT NULL,
  dealer_group_code TEXT NOT NULL,
  dealer_code TEXT NOT NULL,
  dealer_name TEXT,
  dealer_principal UUID,
  appointment_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  country TEXT,
  email TEXT,
  phone TEXT,
  fax TEXT,
  website TEXT,
  address_line1 TEXT,
  address_line2 TEXT,
  address_city TEXT,
  address_state TEXT,
  address_country TEXT,
  address_zipcode TEXT,
  postal_address_line1 TEXT,
  postal_address_line2 TEXT,
  postal_address_city TEXT,
  postal_address_state TEXT,
  postal_address_country TEXT,
  postal_address_zipcode TEXT,
  service_zone_manager UUID,
  sales_zone_manager UUID,
  technical_zone_manager UUID,
  sales_manager UUID,
  service_manager UUID,
  parts_manage  UUID,
  used_car_manager UUID,
  financial_manager UUID,
  regional_manager UUID,
  dom_manager UUID,
  ambassador UUID,
  lincoln_regional_manager UUID,
  imported_source_name IMPORTED_SOURCE_NAMES,
  json_unmapped_fields JSONB,
  source_data JSONB,
  time_inserted TIMESTAMP NOT NULL DEFAULT NOW(),
  time_updated TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT dealer_root_org_dealer_code_pk PRIMARY KEY (root_org, org, dealer_code)
);

-- Create triggers --
CREATE OR REPLACE FUNCTION update_dealer_time_updated() RETURNS TRIGGER AS $trgr_dealer_date_update$
BEGIN
    NEW.time_updated = now();
    RETURN NEW;
END;
$trgr_dealer_date_update$ LANGUAGE plpgsql;

CREATE TRIGGER trgr_dealer_date_update
BEFORE INSERT OR UPDATE ON dealer FOR EACH ROW
EXECUTE PROCEDURE update_dealer_time_updated();

--------------------------------------------------------------------------
--- User Profile Schema
---------------------------------------------------------------------------
DROP TABLE IF EXISTS user_profile;

CREATE TABLE IF NOT EXISTS user_profile(
  root_org TEXT,
  user_id uuid NOT NULL,
  role TEXT,
  teaching_state TEXT,
  organization TEXT,
  profile_image TEXT,
  phone TEXT[],
  public_profiles json[],
  created_on timestamp without time zone,
  created_by TEXT,
  last_updated_on timestamp without time zone,
  last_updated_by TEXT,
  status TEXT,
  about_me TEXT,
  profile_video TEXT,
  cover_image TEXT,
  education jsonb[],
  experience jsonb[],
  awards jsonb[],
  publications jsonb[],
  designation TEXT,
  org_address jsonb[],
  personal_address jsonb[],
  alternate_email TEXT,
  alternate_contacts jsonb[],
  sub_role TEXT[],
  privacy jsonb,
  current_education jsonb,
  json_unmapped_fields jsonb,
  CONSTRAINT pk_user_profile PRIMARY KEY (root_org,user_id),
  CONSTRAINT fk_user_profile_wid FOREIGN KEY (user_id) REFERENCES wingspan_user (wid) ON DELETE CASCADE
);

ALTER TABLE user_profile OWNER to pid;

-------------------------------------------------------------
---- Autogenerate Wingspan Login ID
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_login_id
(p_root_org TEXT, p_org TEXT)
RETURNS TEXT AS $login_id$
DECLARE
  MAX_ID TEXT;
  ID_LENGTH INT;
  SEQ_NUM INT;
  SEQ_NUMBER BIGINT;
  ORG_CODE TEXT;
  ALPHA TEXT;
BEGIN
  IF p_root_org = 'Ford' AND p_org IN ('APDM','ME', 'SSA', 'NAF') THEN
    SELECT MAX(username)
    INTO MAX_ID
    FROM wingspan_user
    WHERE root_org=p_root_org AND org=p_org
    AND is_test_account = false AND username IS NOT NULL;
    IF MAX_ID IS NULL THEN
      IF p_org = 'APDM' THEN
        MAX_ID := 'APDA0001';
      ELSIF p_org = 'ME' THEN
        MAX_ID := 'MEMA0001';
      ELSIF p_org = 'SSA' THEN
        MAX_ID := 'SSAA0001';
      ELSE
        MAX_ID := 'NAFA0001';
      END IF;
    ELSE
      ID_LENGTH := LENGTH(MAX_ID);
      SEQ_NUM := RIGHT(MAX_ID, 4)::INT;
      ORG_CODE := LEFT(MAX_ID, 3);
      ALPHA := substr(MAX_ID, 4, (ID_LENGTH - 7));
      IF SEQ_NUM = 9999 THEN
        IF ALPHA = 'Z' THEN
          RAISE EXCEPTION 'MAX SEQUENCE EXHAUSTED FOR: (%, %)', p_root_org, p_org;
        ELSE
          ALPHA := CHR(ASCII(ALPHA) + 1);
          SEQ_NUM := 1;
        END IF;
      ELSE
        SEQ_NUM := SEQ_NUM + 1;
      END IF;
      MAX_ID := ORG_CODE || ALPHA || LPAD(SEQ_NUM::TEXT, 4, '0');
    END IF;
  ELSIF p_root_org = 'allendigital' THEN
    SELECT MAX(username)
    INTO MAX_ID
    FROM wingspan_user
    WHERE root_org=p_root_org AND username IS NOT NULL AND username::BIGINT>1111111000;
    IF MAX_ID IS NULL THEN
      MAX_ID := '1111111001';
    ELSE
      SEQ_NUMBER := MAX_ID::BIGINT;
      IF SEQ_NUMBER = 9999999999 THEN
        RAISE EXCEPTION 'MAX SEQUENCE EXHAUSTED FOR: %', p_root_org;
      ELSE
        SEQ_NUMBER := SEQ_NUMBER + 1;
      END IF;
      MAX_ID := SEQ_NUMBER::TEXT;
    END IF;
  ELSE
    RAISE EXCEPTION 'AUTO GENERATION NOT ALLOWED FOR: %', p_root_org;
  END IF;
  RETURN MAX_ID;
END;
$login_id$ LANGUAGE plpgsql;

--------------- TABLES CREATION END ---------------
