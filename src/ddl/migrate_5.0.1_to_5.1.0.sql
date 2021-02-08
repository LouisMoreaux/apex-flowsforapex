/*
  Migration Script for Release 5.0.1 to 5.1.0
*/

ALTER TABLE flow_diagrams add dgrm_version  VARCHAR2(10 CHAR) DEFAULT '0' NOT NULL;
ALTER TABLE flow_diagrams add dgrm_status   VARCHAR2(10 CHAR) DEFAULT 'draft' NOT NULL;
ALTER TABLE flow_diagrams add dgrm_category VARCHAR2(30 CHAR);
ALTER TABLE flow_diagrams add dgrm_last_update TIMESTAMP WITH TIME ZONE DEFAULT systimestamp NOT NULL;

ALTER TABLE flow_diagrams DROP CONSTRAINT dgrm_uk;

ALTER TABLE flow_diagrams ADD CONSTRAINT dgrm_uk UNIQUE ( dgrm_name , dgrm_version);

ALTER TABLE flow_diagrams ADD CONSTRAINT dgrm_status_ck CHECK ( dgrm_status in ('draft','released','deprecated','archived'));

CREATE UNIQUE INDEX dgrm_uk2 ON FLOW_DIAGRAMS ( DGRM_NAME, case DGRM_STATUS when 'released' then null else dgrm_version end );