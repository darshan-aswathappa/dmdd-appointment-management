-- =====================================================
-- FILE: 01_create_database.sql
-- PURPOSE: Create the HMS schema owner, set privileges,
--          and provision application users
-- NOTE:    Oracle does not use CREATE DATABASE from SQL.
--          The DBA creates the database instance via DBCA.
--          This script creates users (schemas) and grants.
-- =====================================================

-- =====================================================
-- 1. Create the HMS schema owner
-- The HMS user owns all hospital management objects
-- =====================================================
CREATE USER HMS IDENTIFIED BY "HospitalMS@Pass123"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP;

-- Grant privileges so HMS can create objects
GRANT CREATE SESSION   TO HMS;
GRANT CREATE TABLE     TO HMS;
GRANT CREATE VIEW      TO HMS;
GRANT CREATE PROCEDURE TO HMS;
GRANT CREATE TRIGGER   TO HMS;
GRANT CREATE SEQUENCE  TO HMS;
GRANT UNLIMITED TABLESPACE TO HMS;

-- -------------------------------------------
-- STEP 1.2: Create application users
-- -------------------------------------------
-- admin_user:    Will get full CRUD access (HospitalAdmin role)
-- operator_user: Will get SELECT + EXECUTE access (HospitalOperator role)

CREATE USER admin_user IDENTIFIED BY "AdminPass123"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO admin_user;

CREATE USER operator_user IDENTIFIED BY "OperatorPass456"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO operator_user;

-- -------------------------------------------
-- STEP 1.3: Verify users were created
-- -------------------------------------------
SELECT username, account_status, created
FROM dba_users
WHERE username IN ('HMS', 'ADMIN_USER', 'OPERATOR_USER')
ORDER BY username;
