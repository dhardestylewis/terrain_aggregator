UPDATE aaamissing SET rast = ST_SetSRID(rast,srid) ;
UPDATE aaamissing SET envelope = ST_Envelope(rast) ;
UPDATE aaamissing SET envelope_albers = ST_Transform(envelope,6579) ;
UPDATE aaamissing SET centroid = ST_Centroid(envelope) ;
UPDATE aaamissing SET centroid_albers = ST_Transform(centroid,6579) ;
UPDATE aaamissing SET x = ST_X(centroid) ;
UPDATE aaamissing SET y = ST_Y(centroid) ;
