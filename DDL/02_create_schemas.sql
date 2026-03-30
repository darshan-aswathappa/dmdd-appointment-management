-- =====================================================
-- FILE: 02_create_schemas.sql
-- PURPOSE: Grant schema-level privileges to application
--          users on the HMS schema
-- NOTE:    In Oracle, the schema IS the user. The HMS
--          user was created in 01_create_database.sql.
--          Tables will be created under the HMS schema.
--          This script grants cross-schema access to
--          application users.
-- =====================================================

-- Grant DML privileges on HMS schema objects to admin_user
-- (Specific table-level grants are applied in 06_create_roles_security.sql
--  after the tables exist. These are placeholder privileges.)
GRANT CREATE SESSION TO admin_user;

-- Grant read and write privileges on HMS schema objects to operator_user
GRANT CREATE SESSION TO operator_user;

-- NOTE: Table-level SELECT, INSERT, UPDATE, DELETE grants
-- are applied in 06_create_roles_security.sql after tables are created.
