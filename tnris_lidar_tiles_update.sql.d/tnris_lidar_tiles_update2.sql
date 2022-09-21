UPDATE missing_dem_tiles SET rast = ST_SetSRID(rast,srid) ;
UPDATE missing_dem_tiles SET envelope = ST_Envelope(rast) ;
UPDATE missing_dem_tiles SET envelope_albers = ST_Transform(envelope,6579) ;
UPDATE missing_dem_tiles SET centroid = ST_Centroid(envelope) ;
UPDATE missing_dem_tiles SET centroid_albers = ST_Transform(centroid,6579) ;
UPDATE missing_dem_tiles SET x = ST_X(centroid) ;
UPDATE missing_dem_tiles SET y = ST_Y(centroid) ;
UPDATE missing_dem_tiles SET pixelwidth = ST_PixelWidth(rast) ;
UPDATE missing_dem_tiles SET pixelheight = ST_PixelHeight(rast) ;
/*INSERT INTO tnris_lidar_tiles (rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height, pixelwidth, pixelheight) SELECT rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height, pixelwidth, pixelheight FROM missing_dem_tiles ;*/
