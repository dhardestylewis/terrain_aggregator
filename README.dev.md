# `terrain_aggregator` : how it was developed

1. Create PostgreSQL database of TNRIS Lidar tiles

    - TNRIS provides a [vector file](https://cdn.tnris.org/data/lidar/tnris-lidar_48_vector.zip) indexing the best available Lidar data TNRIS provides on a tile-by-tile basis.
    - However, there are many deficiencies that prevent using this file as a starting point to aggregate Lidar data in bulk, including :
        - only represents "best available" data, not all available TNRIS Lidar data
        - tile geometries are sometimes
            - incorrect :
                - some tile boundaries have
                    - rounded corners where there is data all the way to the corner
                    - intersected with watersheds where there is data beyond the watershed boundaries
                    - chopped along a latitude or longitude where there is data beyond the chop
            - have inconsistently applied boundaries :
                - when tiles overlap each other,
                    - sometimes they are left whole
                    - sometimes they are chopped in favor of the "best available"
        - tile attributes are sometimes
            - `demname` attribute errors :
                - reported resolution incorrect
            - reported resolution is sometimes 

2. Create Docker/Singularity image of 

