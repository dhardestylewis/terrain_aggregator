ALTER TABLE absolutepaths ADD COLUMN path_parts text[], ADD COLUMN project text, ADD COLUMN filename text ;
UPDATE absolutepaths SET path_parts = REGEXP_SPLIT_TO_ARRAY(absolutepath,'/') ;
UPDATE absolutepaths SET project = path_parts[6] ;
UPDATE absolutepaths SET filename = path_parts[8] ;
