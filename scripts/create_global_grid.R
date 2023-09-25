library(rworldmap)
library(terra)

create_grid_polygons <- function(lon_min, lon_max, lat_min, lat_max, total_lon, total_lat, num_lon_chunks, num_lat_chunks) {
    
    # Calculate chunk sizes based on total values and number of chunks
    lon_chunk_size <- total_lon / num_lon_chunks
    lat_chunk_size <- total_lat / num_lat_chunks
    
    # Longitude and latitude step sizes
    lon_step <- (lon_max - lon_min) / total_lon
    lat_step <- (lat_max - lat_min) / total_lat
    
    polygons <- list()
    labels <- numeric()
    
    chunk_index <- 1
    for (ix in seq(lon_min, lon_max - lon_step, by = lon_chunk_size * lon_step)) {
        for (iy in seq(lat_max, lat_min + lat_step, by = -lat_chunk_size * lat_step)) {
            
            # Define the corner coordinates for the current polygon
            top_left <- c(ix, iy)
            top_right <- c(ix + lon_chunk_size * lon_step, iy)
            bottom_right <- c(ix + lon_chunk_size * lon_step, iy - lat_chunk_size * lat_step)
            bottom_left <- c(ix, iy - lat_chunk_size * lat_step)
            
            # Create a polygon and append to the list
            polygon <- rbind(top_left, top_right, bottom_right, bottom_left, top_left)
            polygons <- append(polygons, list(polygon))
            
            # Add the chunk index to the labels list
            labels <- append(labels, chunk_index)
            
            chunk_index <- chunk_index + 1
        }
    }
    
    # Convert the list of polygons to a SpatVector and add labels as attribute
    spat_vect <- vect(polygons, type = "polygons")
    spat_vect$chunk_index <- labels
    
    return(spat_vect)
}


# Parameters
lon_min <- -180
lon_max <- 180
lat_min <- -90
lat_max <- 90
total_lon <- 40000
total_lat <- 20000
num_lon_chunks <- 10
num_lat_chunks <- 10



# Create SpatVector of polygons
grid_polygons <- create_grid_polygons(lon_min, lon_max, lat_min, lat_max, total_lon, total_lat, num_lon_chunks, num_lat_chunks)
plot(vect(getMap()))
plot(grid_polygons, add = T)

centroids <- centroids(grid_polygons)
coords <- crds(centroids)
text(coords[,1], coords[,2], labels=grid_polygons$chunk_index, cex=0.8, adj=c(0.5,0.5))


