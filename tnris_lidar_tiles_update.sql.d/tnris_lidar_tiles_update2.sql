UPDATE aaamissing SET rast = ST_SetSRID(rast,srid) ;
UPDATE aaamissing SET envelope = ST_Envelope(rast) ;
UPDATE aaamissing SET envelope_albers = ST_Transform(envelope,6579) ;
UPDATE aaamissing SET centroid = ST_Centroid(envelope) ;
UPDATE aaamissing SET centroid_albers = ST_Transform(centroid,6579) ;
UPDATE aaamissing SET x = ST_X(centroid) ;
UPDATE aaamissing SET y = ST_Y(centroid) ;
INSERT INTO tnris_lidar_tiles (rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height, pixelwidth, pixelheight) SELECT rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height, pixelwidth, pixelheight FROM aaamissing ;
