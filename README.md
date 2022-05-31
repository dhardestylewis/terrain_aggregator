# The terrain aggregator


The workflow below aggregates terrain tiles from a variety of raster DEM tilesets to a single uniform projection.

Aggregation on a small-country scale takes at most 15 days compute time back-to-front, or about 3000 node-hours of computational time.


# TNRIS Lidar DEM tiles at TACC

@TACC now hosts TNRIS Lidar tiles for TACC users.

To begin using TACC resources, please create a TACC account at the following page:

https://portal.tacc.utexas.edu/account-request

Once you have a TACC account, submit a ticket at the following page and CC dhl@tacc.utexas.edu

https://portal.tacc.utexas.edu/tacc-consulting

# Intermediate retiling results
Intermediate retiling results are available :
- on Stampede2 at :
```bash
stampede2.tacc.utexas.edu:/scratch/04950/dhl/TNRIS-Lidar-retiling/srid_colorinterp_pixeltype.csv.d/3083.vrt.d
```
- and on Corral at :
```bash
data.tacc.utexas.edu:/corral/projects/TDIS/TNRIS-Lidar-retiling/TX_scale
```

# TNRIS Lidar availability
Here is a Shapefile of the extent of each TNRIS Lidar tile:

https://utexas.box.com/v/tnris-lidar-tiles-shp

This shapefile is projected in NAD83 / Texas Centric Albers Equal Area (EPSG:3083):

https://epsg.io/3083

https://spatialreference.org/ref/epsg/nad83-texas-centric-albers-equal-area/

Each tile has the following attributes:
| Attribute | Description |
| --------- | ----------- |
| rast | a reference address to the raster tile on Stampede2 |
| filename | TRNIS Lidar tilename |
| absolutepath | TNRIS Lidar tile absolute path on Stampede2 |
| project | TNRIS Lidar project parent directory name |
| srid | corrected SRID/EPSG code of the tile |
| srid_orig | originally found SRID/EPSG code of the tile |
| pixeltype | datatype of the pixels of the tile (float, integer, etc) |
| envelope | polygon of the extent of the tile projected in the corrected EPSG |
| centroid | centroid of the envelope projected in the corrected EPSG |
| centroid_albers | centroid of the envelope projected in EPSG:3083 |
| x | longitude of the centroid projected in EPSG:3083 |
| y | latitude of the centroid projected in EPSG:3083 |
| width | width of the tile in pixels |
| height | height of the tile in pixels |
| pixelwidth | width of each pixel in EPSG:3083 units (m) |
| pixelheight | height of each pixel in EPSG:3083 units (m) |
| colorinterp | color interpretation of the raster tile |

# Software requirements (on Stampede2)
   - Singularity image : `docker://dhardestylewis/postgis:14-3.2-gdalogr`
   - Conda environment : `https://raw.githubusercontent.com/dhardestylewis/TNRIS-Lidar-PostgreSQL/main/gdal.yml`
   - AWS CLI : `https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html`

## Singularity download and usage

This Singularity image includes support for the following 3 PostgreSQL - GDAL/OGR translators:
   - `raster2pgsql` : to create a PostgreSQL script to add rasters to a PostgreSQL table
   - `shp2pgsql` : to create a PostgreSQL script to add features from a Shapefile to a PostgreSQL table
   - `pgsql2shp` : to create a Shapefile from an existing PostgreSQL table

To download this Singularity image, use the following commands from Stampede2:
```bash
## to enter a computational node: Singularity cannot be used from a development node
idev
## to load the pre-existing Singularity module from TACC's module repository
module load tacc-singularity
## to download this Singularity image from the online Docker Hub image repository
singularity pull docker://dhardestylewis/postgis:14-3.2-gdalogr $SCRATCH/postgis_14-3.2-gdalogr.sif
```

To clone this Git repository, use the following commands from Stampede2:
```bash
git clone https://github.com/dhardestylewis/TNRIS-Lidar-PostgreSQL.git
cd TNRIS-Lidar-PostgreSQL
export TNRIS_LIDAR_POSTGRESQL=$(pwd)
```

To connect to the existing TNRIS Lidar PostgreSQL database, use the following command:
```bash
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run --cleanenv --bind $SCRATCH:/var $SCRATCH/postgis_14-3.2-gdalogr.sif &
for filename in $(ls ${TNRIS_LIDAR_POSTGRESQL}/TNRIS-Lidar-Tiles.sql.d/*.sql); do SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity exec --cleanenv --bind $SCRATCH:/var $SCRATCH/postgis_14-3.2-gdalogr.sif psql -U postgres -d postgres -h 127.0.0.1 -f ${filename}; done
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity exec --cleanenv --bind $SCRATCH:/var $SCRATCH/postgis_14-3.2-gdalogr.sif psql -U postgres -d postgres -h 127.0.0.1
```

Please submit a ticket if you don't have permission to access this database and be sure to CC dhl@tacc.utexas.edu

https://portal.tacc.utexas.edu/tacc-consulting

*Note :* Please wait for the following output before trying to access this database:
```bash
LOG:  database system is ready to accept connections
```

# Updating the database with new Lidar tiles

To populate the database with newly added tiles, the following commands can be used to generate a list of raster tiles to add to the table

```bash
cds
mkdir tnris-lidardata
cd tnris-lidardata
export TNRIS_LIDAR_DATA=$(pwd)
cd ..
aws s3 cp s3://tnris-public-data/production-data/ tnris-lidardata --recursive
```

For reference, TNRIS's AWS S3 bucket of their Lidar data can be publicly accessed at the following URL:

https://s3.console.aws.amazon.com/s3/buckets/tnris-public-data?region=us-east-1&prefix=production-data/

From the parent directory of TNRIS Lidar data, on the command line:
```bash
find $(pwd) -maxdepth 4 -type f -wholename "*/dem/*.tif" -o -wholename "*/dem/*.img" -o -wholename "*/dem/*.dem" > $WORK/find_dem_tiles.csv
sort -u $WORK/find_dem_tiles.csv > $WORK/find_dem_tiles-sorted.csv
mv $WORK/find_dem_tiles-sorted.csv $WORK/find_dem_tiles.csv
```

From the PostgreSQL database:
```sql
/* replace the following CSV path with your equivalent */
COPY (SELECT absolutepath FROM tnris_lidar_tiles ORDER BY absolutepath) TO '$SCRATCH/select_all_dem_tiles.csv' (FORMAT csv) ;
```

```bash
comm -23 $SCRATCH/find_dem_tiles.csv $SCRATCH/select_all_dem_tiles.csv > $WORK2/missing_dem_tiles.csv

## Run raster2pgsql from the Singularity image
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity exec --cleanenv --bind $SCRATCH:/var $SCRATCH/postgis_14-3.2-gdalogr.sif bash
```
```bash
## From the Singularity container connected to the database
raster2pgsql -R -F -Y -I -M -e $(cat $WORK2/missing_dem_tiles.csv | tr "\n" " ") public.missing_dem_tiles > $WORK2/missing_dem_tiles.sql

## Once this is done, load the tiles' metadata to the PostgreSQL database using the following command
psql -U postgres -d postgres -h 127.0.0.1 -f $WORK2/missing_dem_tiles.sql
```

From the PostgreSQL database:
```sql
CREATE TABLE missing_dem_tiles_paths (absolutepath text) ;
/* Be sure to replace the following CSV path with your specific CSV path */
COPY missing_dem_tiles_paths FROM '$WORK2/missing_dem_tiles.csv' WITH (FORMAT csv) ;
```

From the command line:
```bash
## Add the following columns to the table:
##     - project
##     - filename
##     - absolutepath
##     - srid_orig
##     - srid
##     - pixeltype
##     - x
##     - y
##     - width
##     - height
## and populate the following columns with metadata:
##     - project : TNRIS Lidar project parent directory name
##     - filename : TRNIS Lidar tilename
##     - absolutepath : TNRIS Lidar tile absolute path on Stampede2
##     - srid_orig : originally found SRID/EPSG code of the tile
##     - srid : corrected SRID/EPSG code of the tile
##     - pixeltype : datatype of the pixels of the tile (float, integer, etc)
##     - width : width of the tile in pixels
##     - height : height of the tile in pixels
##     - pixelwidth : width of each pixel in EPSG:3083 (m)
##     - pixelheight : height of each pixel in EPSG:3083 (m)
psql -U postgres -d postgres -h 127.0.0.1 -f $TNRIS_LIDAR_POSTGRESQL/tnris_lidar_tiles_update.sql.d/tnris_lidar_tiles_update1.sql
```

From the PostgreSQL database:
```sql
/* Check to see if the GDAL driver failed to find any of the tiles' projections */
SELECT COUNT(DISTINCT(absolutepath)) FROM missing_dem_tiles WHERE srid_orig = 0 ;
/* If any tiles are found above, it will be necessary to correct the projection information for these tiles. I leave it to the user to determine how to do that. I provide the `srid` column to record corrected projections. Once all of the tiles' projections have been corrected, the following selection should return 0 */
SELECT COUNT(DISTINCT(absolutepath)) FROM missing_dem_tiles WHERE srid = 0 ;
```

From the command line:
```bash
## Populate the following columns with correct(ed) metadata:
##     - rast : raster tile geometry in the corrected SRID/EPSG code)
##     - envelope : envelope of the raster tile
##     - envelope_albers : envelope reprojected to NAD83(2011) / Texas Centric Albers Equal Area
##     - centroid : centroid of the envelope
##     - centroid_albers : centroid reprojected to NAD83(2011) / Texas Centric Albers Equal Area
##     - x : latitudinal coordinate of the centroid in original projection
##     - y : longitudinal coordinate of the centroid in the orignal projection
psql -U postgres -d postgres -h 127.0.0.1 -f $TNRIS_LIDAR_POSTGRESQL/tnris_lidar_tiles_update.sql.d/tnris_lidar_tiles_update2.sql
## It is necessary to set the `colorinterp` attribute separately
```

From the PostgreSQL database:
```sql
/* Join the original table with the missing tiles table */
CREATE TABLE updated_tnris_lidar_tiles AS (SELECT rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height FROM tnris_lidar_tiles UNION SELECT rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height FROM missing_dem_tiles) ;
DROP TABLE tnris_lidar_tiles ;
DROP TABLE missing_dem_tiles ;
ALTER TABLE updated_tnris_lidar_tiles RENAME TO tnris_lidar_tiles ;
```

Once this table is corrected, the following command can be run from the PostGIS Singularity image command line to generate a new TNRIS Lidar availability file:
```bash
pgsql2shp -f $WORK2/TNRIS-Lidar-Corrected_availability_file.shp -h 127.0.0.1 -P pgpass -u postgres -g envelope_albers -k postgres public.tnris_lidar_tiles
```

*QAQC :* Keep in mind that a visual inspection of the resulting Shapefile is necessary in order to ensure that the tiles are all now in the correct projection.

# Retiling workflow

PostgreSQL:
```sqlthe
/* Replace with your preferred location below */
COPY (SELECT DISTINCT(srid) FROM tnris_lidar_tiles) TO '/scratch/04950/dhl/distinct_srid.csv' (FORMAT csv) ;
```

Create and activate the Conda environment from the command line:
```bash
conda env create -f $TNRIS_LIDAR_POSTGRESQL/gdal.yml
conda activate gdal
```

Command line:
```bash
## Please note that any tiles whose pixeltype != Float32 will need to be pre-treated with the following command before starting this workflow.
##  Thus far, ~142 tiles from the following two projects are impacted:
##   - capcog-2007-140cm-caldwell-travis-williamson
##   - usgs-2016-70cm-middle-brazos-lake-whitney
# gdal_translate -ot Float32 src_dataset dst_dataset.vrt
## It will be necessary to substitute in these VRTs for the source tiles in the following `gdalbuildvrt` file lists

## Create a file list of each tileset grouped by SRID/EPSG code:
while read srid; do psql -d postgres -t -A -F"," -c "SELECT absolutepath FROM tnris_lidar_tiles WHERE srid = ${srid}" > ${srid}.srid ; done < $TNRIS_LIDAR_POSTGRESQL/distinct_srid.csv

## Conduct a `gdalbuildvrt` for each unique EPSG:
for filename in $(ls *.srid); do gdalbuildvrt -resolution highest -allow_projection_difference -vrtnodata -9999. -a_srs EPSG:$(basename ${filename} .srid) -input_file_list ${filename} -overwrite ${filename}.vrt; done

## Conduct a `gdal_translate` for each unique EPSG's VRT:
for filename in $(ls *.srid); do gdal_translate -colorinterp undefined ${filename}.vrt ${filename}-translated.vrt; done

## Conduct a `gdalwarp` for each unique EPSG's VRT:
for filename in $(ls *.srid); do gdalwarp -t_srs EPSG:3083 -multi -overwrite -setci ${filename}-translated.vrt ${filename}-warped.vrt; done

## EPSGs 2277-2279 will require manual intervention in order to tile successfully.
## They have a vertical datum of NAVD88 (ftUS).
## Run the following command to shift their pixel values to NAVD88 (m):
for filename in $(ls 227[7-9].srid); do gdalwarp -s_srs $(basename ${filename} .srid)+6360 -t_srs EPSG:3083+5703 -multi -overwrite -setci ${filename}-translated.vrt ${filename}-warped.vrt; done

## Conduct a `gdalbuildvrt` to create a VRT of warped VRTs:
gdalbuildvrt -resolution highest albers-warped.vrt *-warped.vrt

## Conduct a retiling:
mkdir albers-warped.d
gdal_retile.py -overlap 100 -tileIndex albers-warped.shp -csv albers-warped.csv -ps 1600 1600 -levels 20 -resume -targetDir albers-warped.d albers-warped.vrt

## Create a VRT of the retiles:
gdalbuildvrt -resolution highest albers-warped.d.vrt albers-warped.d/*.tif

## Crop watershed-delineated DEMs from these retiles, using features labelled by the `index` attribute in a separate vector image
mkdir HUCs.d
NUMBER_OF_HUCS=739
for huc in $(seq 0 $(( ${NUMBER_OF_HUCS} - 1)) ); do gdalwarp -multi -cutline HUCs.shp -cl HUCs -cwhere "index=${huc}" -crop_to_cutline albers-warped.d.vrt HUCs.d/HUC${huc}.tif ; done
```

# Testing environment
- [Stampede2](https://www.tacc.utexas.edu/systems/stampede2)
- [KNL node](https://portal.tacc.utexas.edu/user-guides/stampede2#knl-compute-nodes)
```bash
1) intel/18.0.2      3) impi/18.0.2   5) autotools/1.1    7) cmake/3.16.1   9) TACC
2) libfabric/1.7.0   4) git/2.24.1    6) python2/2.7.15   8) xalt/2.10.2
```

# LICENSE for this documentation:

https://www.gnu.org/licenses/fdl-1.3.en.html


Copyright (C)  2022  Daniel Hardesty Lewis.
Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled "GNU
Free Documentation License".


GNU Free Documentation License
Version 1.3, 3 November 2008

Copyright © 2000, 2001, 2002, 2007, 2008 Free Software Foundation, Inc. <https://fsf.org/>

Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.

0. PREAMBLE
The purpose of this License is to make a manual, textbook, or other functional and useful document "free" in the sense of freedom: to assure everyone the effective freedom to copy and redistribute it, with or without modifying it, either commercially or noncommercially. Secondarily, this License preserves for the author and publisher a way to get credit for their work, while not being considered responsible for modifications made by others.

This License is a kind of "copyleft", which means that derivative works of the document must themselves be free in the same sense. It complements the GNU General Public License, which is a copyleft license designed for free software.

We have designed this License in order to use it for manuals for free software, because free software needs free documentation: a free program should come with manuals providing the same freedoms that the software does. But this License is not limited to software manuals; it can be used for any textual work, regardless of subject matter or whether it is published as a printed book. We recommend this License principally for works whose purpose is instruction or reference.

1. APPLICABILITY AND DEFINITIONS
This License applies to any manual or other work, in any medium, that contains a notice placed by the copyright holder saying it can be distributed under the terms of this License. Such a notice grants a world-wide, royalty-free license, unlimited in duration, to use that work under the conditions stated herein. The "Document", below, refers to any such manual or work. Any member of the public is a licensee, and is addressed as "you". You accept the license if you copy, modify or distribute the work in a way requiring permission under copyright law.

A "Modified Version" of the Document means any work containing the Document or a portion of it, either copied verbatim, or with modifications and/or translated into another language.

A "Secondary Section" is a named appendix or a front-matter section of the Document that deals exclusively with the relationship of the publishers or authors of the Document to the Document's overall subject (or to related matters) and contains nothing that could fall directly within that overall subject. (Thus, if the Document is in part a textbook of mathematics, a Secondary Section may not explain any mathematics.) The relationship could be a matter of historical connection with the subject or with related matters, or of legal, commercial, philosophical, ethical or political position regarding them.

The "Invariant Sections" are certain Secondary Sections whose titles are designated, as being those of Invariant Sections, in the notice that says that the Document is released under this License. If a section does not fit the above definition of Secondary then it is not allowed to be designated as Invariant. The Document may contain zero Invariant Sections. If the Document does not identify any Invariant Sections then there are none.

The "Cover Texts" are certain short passages of text that are listed, as Front-Cover Texts or Back-Cover Texts, in the notice that says that the Document is released under this License. A Front-Cover Text may be at most 5 words, and a Back-Cover Text may be at most 25 words.

A "Transparent" copy of the Document means a machine-readable copy, represented in a format whose specification is available to the general public, that is suitable for revising the document straightforwardly with generic text editors or (for images composed of pixels) generic paint programs or (for drawings) some widely available drawing editor, and that is suitable for input to text formatters or for automatic translation to a variety of formats suitable for input to text formatters. A copy made in an otherwise Transparent file format whose markup, or absence of markup, has been arranged to thwart or discourage subsequent modification by readers is not Transparent. An image format is not Transparent if used for any substantial amount of text. A copy that is not "Transparent" is called "Opaque".

Examples of suitable formats for Transparent copies include plain ASCII without markup, Texinfo input format, LaTeX input format, SGML or XML using a publicly available DTD, and standard-conforming simple HTML, PostScript or PDF designed for human modification. Examples of transparent image formats include PNG, XCF and JPG. Opaque formats include proprietary formats that can be read and edited only by proprietary word processors, SGML or XML for which the DTD and/or processing tools are not generally available, and the machine-generated HTML, PostScript or PDF produced by some word processors for output purposes only.

The "Title Page" means, for a printed book, the title page itself, plus such following pages as are needed to hold, legibly, the material this License requires to appear in the title page. For works in formats which do not have any title page as such, "Title Page" means the text near the most prominent appearance of the work's title, preceding the beginning of the body of the text.

The "publisher" means any person or entity that distributes copies of the Document to the public.

A section "Entitled XYZ" means a named subunit of the Document whose title either is precisely XYZ or contains XYZ in parentheses following text that translates XYZ in another language. (Here XYZ stands for a specific section name mentioned below, such as "Acknowledgements", "Dedications", "Endorsements", or "History".) To "Preserve the Title" of such a section when you modify the Document means that it remains a section "Entitled XYZ" according to this definition.

The Document may include Warranty Disclaimers next to the notice which states that this License applies to the Document. These Warranty Disclaimers are considered to be included by reference in this License, but only as regards disclaiming warranties: any other implication that these Warranty Disclaimers may have is void and has no effect on the meaning of this License.

2. VERBATIM COPYING
You may copy and distribute the Document in any medium, either commercially or noncommercially, provided that this License, the copyright notices, and the license notice saying this License applies to the Document are reproduced in all copies, and that you add no other conditions whatsoever to those of this License. You may not use technical measures to obstruct or control the reading or further copying of the copies you make or distribute. However, you may accept compensation in exchange for copies. If you distribute a large enough number of copies you must also follow the conditions in section 3.

You may also lend copies, under the same conditions stated above, and you may publicly display copies.

3. COPYING IN QUANTITY
If you publish printed copies (or copies in media that commonly have printed covers) of the Document, numbering more than 100, and the Document's license notice requires Cover Texts, you must enclose the copies in covers that carry, clearly and legibly, all these Cover Texts: Front-Cover Texts on the front cover, and Back-Cover Texts on the back cover. Both covers must also clearly and legibly identify you as the publisher of these copies. The front cover must present the full title with all words of the title equally prominent and visible. You may add other material on the covers in addition. Copying with changes limited to the covers, as long as they preserve the title of the Document and satisfy these conditions, can be treated as verbatim copying in other respects.

If the required texts for either cover are too voluminous to fit legibly, you should put the first ones listed (as many as fit reasonably) on the actual cover, and continue the rest onto adjacent pages.

If you publish or distribute Opaque copies of the Document numbering more than 100, you must either include a machine-readable Transparent copy along with each Opaque copy, or state in or with each Opaque copy a computer-network location from which the general network-using public has access to download using public-standard network protocols a complete Transparent copy of the Document, free of added material. If you use the latter option, you must take reasonably prudent steps, when you begin distribution of Opaque copies in quantity, to ensure that this Transparent copy will remain thus accessible at the stated location until at least one year after the last time you distribute an Opaque copy (directly or through your agents or retailers) of that edition to the public.

It is requested, but not required, that you contact the authors of the Document well before redistributing any large number of copies, to give them a chance to provide you with an updated version of the Document.

4. MODIFICATIONS
You may copy and distribute a Modified Version of the Document under the conditions of sections 2 and 3 above, provided that you release the Modified Version under precisely this License, with the Modified Version filling the role of the Document, thus licensing distribution and modification of the Modified Version to whoever possesses a copy of it. In addition, you must do these things in the Modified Version:

A. Use in the Title Page (and on the covers, if any) a title distinct from that of the Document, and from those of previous versions (which should, if there were any, be listed in the History section of the Document). You may use the same title as a previous version if the original publisher of that version gives permission.
B. List on the Title Page, as authors, one or more persons or entities responsible for authorship of the modifications in the Modified Version, together with at least five of the principal authors of the Document (all of its principal authors, if it has fewer than five), unless they release you from this requirement.
C. State on the Title page the name of the publisher of the Modified Version, as the publisher.
D. Preserve all the copyright notices of the Document.
E. Add an appropriate copyright notice for your modifications adjacent to the other copyright notices.
F. Include, immediately after the copyright notices, a license notice giving the public permission to use the Modified Version under the terms of this License, in the form shown in the Addendum below.
G. Preserve in that license notice the full lists of Invariant Sections and required Cover Texts given in the Document's license notice.
H. Include an unaltered copy of this License.
I. Preserve the section Entitled "History", Preserve its Title, and add to it an item stating at least the title, year, new authors, and publisher of the Modified Version as given on the Title Page. If there is no section Entitled "History" in the Document, create one stating the title, year, authors, and publisher of the Document as given on its Title Page, then add an item describing the Modified Version as stated in the previous sentence.
J. Preserve the network location, if any, given in the Document for public access to a Transparent copy of the Document, and likewise the network locations given in the Document for previous versions it was based on. These may be placed in the "History" section. You may omit a network location for a work that was published at least four years before the Document itself, or if the original publisher of the version it refers to gives permission.
K. For any section Entitled "Acknowledgements" or "Dedications", Preserve the Title of the section, and preserve in the section all the substance and tone of each of the contributor acknowledgements and/or dedications given therein.
L. Preserve all the Invariant Sections of the Document, unaltered in their text and in their titles. Section numbers or the equivalent are not considered part of the section titles.
M. Delete any section Entitled "Endorsements". Such a section may not be included in the Modified Version.
N. Do not retitle any existing section to be Entitled "Endorsements" or to conflict in title with any Invariant Section.
O. Preserve any Warranty Disclaimers.
If the Modified Version includes new front-matter sections or appendices that qualify as Secondary Sections and contain no material copied from the Document, you may at your option designate some or all of these sections as invariant. To do this, add their titles to the list of Invariant Sections in the Modified Version's license notice. These titles must be distinct from any other section titles.

You may add a section Entitled "Endorsements", provided it contains nothing but endorsements of your Modified Version by various parties—for example, statements of peer review or that the text has been approved by an organization as the authoritative definition of a standard.

You may add a passage of up to five words as a Front-Cover Text, and a passage of up to 25 words as a Back-Cover Text, to the end of the list of Cover Texts in the Modified Version. Only one passage of Front-Cover Text and one of Back-Cover Text may be added by (or through arrangements made by) any one entity. If the Document already includes a cover text for the same cover, previously added by you or by arrangement made by the same entity you are acting on behalf of, you may not add another; but you may replace the old one, on explicit permission from the previous publisher that added the old one.

The author(s) and publisher(s) of the Document do not by this License give permission to use their names for publicity for or to assert or imply endorsement of any Modified Version.

5. COMBINING DOCUMENTS
You may combine the Document with other documents released under this License, under the terms defined in section 4 above for modified versions, provided that you include in the combination all of the Invariant Sections of all of the original documents, unmodified, and list them all as Invariant Sections of your combined work in its license notice, and that you preserve all their Warranty Disclaimers.

The combined work need only contain one copy of this License, and multiple identical Invariant Sections may be replaced with a single copy. If there are multiple Invariant Sections with the same name but different contents, make the title of each such section unique by adding at the end of it, in parentheses, the name of the original author or publisher of that section if known, or else a unique number. Make the same adjustment to the section titles in the list of Invariant Sections in the license notice of the combined work.

In the combination, you must combine any sections Entitled "History" in the various original documents, forming one section Entitled "History"; likewise combine any sections Entitled "Acknowledgements", and any sections Entitled "Dedications". You must delete all sections Entitled "Endorsements".

6. COLLECTIONS OF DOCUMENTS
You may make a collection consisting of the Document and other documents released under this License, and replace the individual copies of this License in the various documents with a single copy that is included in the collection, provided that you follow the rules of this License for verbatim copying of each of the documents in all other respects.

You may extract a single document from such a collection, and distribute it individually under this License, provided you insert a copy of this License into the extracted document, and follow this License in all other respects regarding verbatim copying of that document.

7. AGGREGATION WITH INDEPENDENT WORKS
A compilation of the Document or its derivatives with other separate and independent documents or works, in or on a volume of a storage or distribution medium, is called an "aggregate" if the copyright resulting from the compilation is not used to limit the legal rights of the compilation's users beyond what the individual works permit. When the Document is included in an aggregate, this License does not apply to the other works in the aggregate which are not themselves derivative works of the Document.

If the Cover Text requirement of section 3 is applicable to these copies of the Document, then if the Document is less than one half of the entire aggregate, the Document's Cover Texts may be placed on covers that bracket the Document within the aggregate, or the electronic equivalent of covers if the Document is in electronic form. Otherwise they must appear on printed covers that bracket the whole aggregate.

8. TRANSLATION
Translation is considered a kind of modification, so you may distribute translations of the Document under the terms of section 4. Replacing Invariant Sections with translations requires special permission from their copyright holders, but you may include translations of some or all Invariant Sections in addition to the original versions of these Invariant Sections. You may include a translation of this License, and all the license notices in the Document, and any Warranty Disclaimers, provided that you also include the original English version of this License and the original versions of those notices and disclaimers. In case of a disagreement between the translation and the original version of this License or a notice or disclaimer, the original version will prevail.

If a section in the Document is Entitled "Acknowledgements", "Dedications", or "History", the requirement (section 4) to Preserve its Title (section 1) will typically require changing the actual title.

9. TERMINATION
You may not copy, modify, sublicense, or distribute the Document except as expressly provided under this License. Any attempt otherwise to copy, modify, sublicense, or distribute it is void, and will automatically terminate your rights under this License.

However, if you cease all violation of this License, then your license from a particular copyright holder is reinstated (a) provisionally, unless and until the copyright holder explicitly and finally terminates your license, and (b) permanently, if the copyright holder fails to notify you of the violation by some reasonable means prior to 60 days after the cessation.

Moreover, your license from a particular copyright holder is reinstated permanently if the copyright holder notifies you of the violation by some reasonable means, this is the first time you have received notice of violation of this License (for any work) from that copyright holder, and you cure the violation prior to 30 days after your receipt of the notice.

Termination of your rights under this section does not terminate the licenses of parties who have received copies or rights from you under this License. If your rights have been terminated and not permanently reinstated, receipt of a copy of some or all of the same material does not give you any rights to use it.

10. FUTURE REVISIONS OF THIS LICENSE
The Free Software Foundation may publish new, revised versions of the GNU Free Documentation License from time to time. Such new versions will be similar in spirit to the present version, but may differ in detail to address new problems or concerns. See https://www.gnu.org/licenses/.

Each version of the License is given a distinguishing version number. If the Document specifies that a particular numbered version of this License "or any later version" applies to it, you have the option of following the terms and conditions either of that specified version or of any later version that has been published (not as a draft) by the Free Software Foundation. If the Document does not specify a version number of this License, you may choose any version ever published (not as a draft) by the Free Software Foundation. If the Document specifies that a proxy can decide which future versions of this License can be used, that proxy's public statement of acceptance of a version permanently authorizes you to choose that version for the Document.

11. RELICENSING
"Massive Multiauthor Collaboration Site" (or "MMC Site") means any World Wide Web server that publishes copyrightable works and also provides prominent facilities for anybody to edit those works. A public wiki that anybody can edit is an example of such a server. A "Massive Multiauthor Collaboration" (or "MMC") contained in the site means any set of copyrightable works thus published on the MMC site.

"CC-BY-SA" means the Creative Commons Attribution-Share Alike 3.0 license published by Creative Commons Corporation, a not-for-profit corporation with a principal place of business in San Francisco, California, as well as future copyleft versions of that license published by that same organization.

"Incorporate" means to publish or republish a Document, in whole or in part, as part of another Document.

An MMC is "eligible for relicensing" if it is licensed under this License, and if all works that were first published under this License somewhere other than this MMC, and subsequently incorporated in whole or in part into the MMC, (1) had no cover texts or invariant sections, and (2) were thus incorporated prior to November 1, 2008.

The operator of an MMC Site may republish an MMC contained in the site under CC-BY-SA on the same site at any time before August 1, 2009, provided the MMC is eligible for relicensing.

ADDENDUM: How to use this License for your documents
To use this License in a document you have written, include a copy of the License in the document and put the following copyright and license notices just after the title page:

    Copyright (C)  YEAR  YOUR NAME.
    Permission is granted to copy, distribute and/or modify this document
    under the terms of the GNU Free Documentation License, Version 1.3
    or any later version published by the Free Software Foundation;
    with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
    A copy of the license is included in the section entitled "GNU
    Free Documentation License".
If you have Invariant Sections, Front-Cover Texts and Back-Cover Texts, replace the "with … Texts." line with this:

    with the Invariant Sections being LIST THEIR TITLES, with the
    Front-Cover Texts being LIST, and with the Back-Cover Texts being LIST.
If you have Invariant Sections without Cover Texts, or some other combination of the three, merge those two alternatives to suit the situation.

If your document contains nontrivial examples of program code, we recommend releasing these examples in parallel under your choice of free software license, such as the GNU General Public License, to permit their use in free software.
