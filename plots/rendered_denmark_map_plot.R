# libraries we need
libs <- c("rayshader", "tidyverse", "sf", 
          "classInt", "giscoR", "terra", "exactextractr", "plyr", "ggplot2")

# install missing libraries
installed_libs <- libs %in% rownames(installed.packages())
if (any(installed_libs == F)) {
  install.packages(libs[!installed_libs])
}

library(plyr)
library(ggplot2)

# load libraries
invisible(lapply(libs, library, character.only = T))

# define longlat CRS
crsLONGLAT <- "+proj=longlat +datum=WGS84 +no_defs"

# 1. GET DENMARK SF DATA
#---------
get_denmark_sf <- function(denmark, denmark_hex, denmark_sf) {
  
  denmark <- giscoR::gisco_get_countries(
    year = "2016",
    epsg = "4326",
    resolution = "01",
    country = "Denmark")  %>% 
    st_transform(3575)
  
  # Make grid of circa 30,000 m2
  denmark_hex <- st_make_grid(denmark, 
                             cellsize = ((3 * sqrt(3) * 107^2)/2)/20, 
                             what = "polygons", 
                             square = F) %>%
    st_intersection(denmark) %>%
    st_sf() %>%
    mutate(id = row_number()) %>% filter(
      st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON")) %>% 
    st_cast("MULTIPOLYGON") #transform to multipolygons
  
  denmark_sf <- st_transform(denmark_hex, crs = crsLONGLAT) #transform back to longlat
  
  return(denmark_sf)
}

# 3. AGGREGATE OBSERVATIONS
#---------
file_path <- "/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/data/simple_data_shortened.csv"
file_path2 <- "/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/data/simple_data_filtered.csv"

get_denmark_observations_agg <- function(denmark_sf, df) {
  # Convert df to sf object
  df_sf <- st_as_sf(df, coords = c("decimalLongitude", "decimalLatitude"), crs = crsLONGLAT)
  
  # Ensure both datasets use the same CRS
  df_sf <- st_transform(df_sf, st_crs(denmark_sf))
  
  # Spatial join to count observations in each hex cell
  denmark_sf$observations <- lengths(st_intersects(denmark_sf, df_sf))
  
  return(denmark_sf)
}

# Usage
denmark_sf <- get_denmark_sf()
df <- read_csv(file_path2)

denmark_sf_with_observations <- get_denmark_observations_agg(denmark_sf, df)


# 5. MERGE NEW DF WITH HEX OBJECT
#---------

get_denmark_final <- function(denmark_sf) {
  # Remove empty geometries if any
  f <- denmark_sf %>%
    filter(!st_is_empty(.)) %>%
    st_as_sf()
  
  # Rename 'observations' column to 'val' for consistency
  names(f)[which(names(f) == "observations")] <- "val"
  
  # Replace NA values with 0
  f$val[is.na(f$val)] <- 0
  
  return(f)
}

# Usage
f <- get_denmark_final(denmark_sf_with_observations)

# 6. GENERATE BREAKS AND COLORS
#---------

get_breaks <- function(f) {
  vmin <- min(f$val, na.rm = TRUE)
  vmax <- max(f$val, na.rm = TRUE)
  
  # Use n = 20 for 20 breaks
  brk <- round(classIntervals(f$val, n = 20, style = 'fisher')$brks, 1)
  
  # Adjust the breaks as needed
  brk <- brk %>% head(-1) %>% tail(-1) %>% append(vmax)
  
  breaks <- c(vmin, brk)
  all_breaks <- list(vmin = vmin, vmax = vmax, breaks = breaks)
  return(all_breaks)
}

get_colors <- function() {
  # Base colors remain the same
  cols <- rev(c("#1b3104", "#386c2e", 
                         "#498c44", "#5bad5d", "#8dc97f", "#c4e4a7"))
                         
  newcol <- colorRampPalette(cols)
  ncols <- 20  # Update to 20 colors
  cols2 <- newcol(ncols)
  
  return(cols2)
}

# Add small offset to avoid zero in log scale
breaks_list <- get_breaks(f)
colors <- get_colors()

p <- ggplot() +
  geom_sf(data = f, aes(fill = val + 1), color = NA) +  # Add offset to avoid log(0) if needed
  scale_fill_gradientn(
    colors = colors,
    trans = "log10",  # Apply square root transformation
    guide = guide_colorbar(
      direction = "horizontal",
      reverse = T,
      title.position = "bottom",      # Position the legend title at the bottom
      title.hjust = 0.5,              # Center the legend title
      label.position = "bottom",      # Position the labels at the bottom
      label.hjust = 0.5,              # Center the labels
      barwidth = unit(15, "lines"),
      title.theme = element_text(size = 14, vjust = 0.5),  # Increase title size and adjust vertical position
      label.theme = element_text(size = 12, vjust = 0.5, angle = 30, margin = margin(t = 5, unit = "pt"))  # Increase label size, rotate, and add top margin
    )
  ) +
  theme_minimal() +
  labs(
    fill = "Observations",
    title = "Fungi Observations in The Kingdom of Denmark",
    subtitle = "Aggregated by Hex Grid",
    caption = "Data Source: GBIF.org (30 October 2024) GBIF Occurrence Download https://doi.org/10.15468/dl.2ngspp",
    x = "", 
    y = NULL
  ) +
  theme(
    text = element_text(family = "Georgia", color = "#22211d"),
    axis.line = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    
    # Legend customization
    legend.position = c(0.7, 0.8),    # Position the legend inside the plot (adjust as needed)
    legend.text = element_text(size = 12, color = "black"),   # Increased text size from 8 to 12
    legend.title = element_text(size = 14, color = "black"),  # Increased title size from 10 to 14
    
    panel.grid.major = element_line(color = "#a0d5de", size = 0.2),
    panel.grid.minor = element_blank(),
    
    plot.title = element_text(size = 16, color = "#498c44", hjust = 0.6, face = "bold", vjust = 1),
    plot.subtitle = element_text(size = 12, color = "#498c44", hjust = 0.6),
    plot.caption = element_text(size = 6, color = "black", hjust = 0.15, vjust = 20),
    
    plot.margin = unit(c(t = 1, r = 1, b = 1, l = 1), "lines"),
    plot.background = element_rect(fill = "#a0d5de", color = NA),
    panel.background = element_rect(fill = "#a0d5de", color = NA),
    legend.background = element_rect(fill = "#a0d5de", color = NA),
    panel.border = element_blank()
  )

# Display the Plot
print(p)

ggsave(file = "/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/denmark_swamp_2d.svg",
       plot = p, 
       width = 15, height = 8)

plot_gg(p,
        multicore = T,
        width=10,
        height=10,
        scale=300,
        shadow_intensity = .75,
        sunangle = 320,
        #offset_edges=T,
        windowsize=c(2500,2000),
        zoom = .8,
        raytrace = TRUE,
        phi = 60,
        theta = 30)

render_snapshot("/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/denmark_swamp_maptester.png", clear=T)

#######

#########
round_function <- function(n) {
  ifelse(round(n) <= 10, round(n), paste0(">", round_any(n, 10)))
}

# 2. DEFINE THE PLOTTING FUNCTION WITH LOG TRANSFORMATION
get_denmark_map <- function(f) {
  # Get breaks and colors
  breaks_list <- get_breaks(f)
  vmin <- breaks_list$vmin
  vmax <- breaks_list$vmax
  breaks <- breaks_list$breaks
  cols2 <- get_colors()
  
  # Create the plot
  p <- ggplot(f) +
    geom_sf(aes(fill = val + 1), color = NA, size = 0) +  # Add offset to avoid log(0)
    scale_fill_gradientn(
      name = "Observations",
      colours = cols2,
      trans = "sqrt"  # Apply log10 transformation
    ) +
    guides(fill = guide_legend(
      direction = "horizontal",
      nrow = 1,  # Ensure legend is in one row
      keyheight = unit(5, units = "mm"),
      keywidth = unit(10, units = "mm"),  # Increase key width for clarity
      title.position = 'bottom',
      title.hjust = 0.5,
      label.hjust = 0.5,
      reverse = TRUE,
      label.position = "bottom"
    )) +
    coord_sf(crs = crsLONGLAT) +
    theme_minimal() +
    theme(
      text = element_text(family = "Georgia", color = "#22211d"),
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      legend.position = c(0.7, 0.7),    # Position legend inside the plot
      legend.text = element_text(size = 8, color = "black"),   # Adjust text size and color
      legend.title = element_text(size = 10, color = "black"), # Adjust title size and color
      panel.grid.major = element_line(color = "#a0d5de", size = 0.2),
      panel.grid.minor = element_blank(),
      plot.title = element_text(size = 20, color = "#498c44", hjust = 0.6, face = "bold", vjust = 1),
      plot.subtitle = element_text(size = 14, color = "#498c44", hjust = 0.6),
      plot.caption = element_text(size = 10, color = "black", hjust = 0.15, vjust = 10),
      plot.margin = unit(c(t = 1, r = 1, b = 1, l = 1), "lines"),
      plot.background = element_rect(fill = "#a0d5de", color = NA),
      panel.background = element_rect(fill = "#a0d5de", color = NA),
      legend.background = element_rect(fill = "#a0d5de", color = NA),
      panel.border = element_blank()
    ) +
    labs(
      x = "", 
      y = NULL, 
      title = "Fungi Observations in The Kingdom of Denmark", 
      subtitle = "Aggregated by Hex Grid", 
      caption = "Data Source: GBIF.org (30 October 2024) GBIF Occurrence Download https://doi.org/10.15468/dl.2ngspp"
    )
  
  return(p)
}

p <- get_denmark_map(f) + theme(legend.position = "none")

p

plot_gg(p,
        multicore = T,
        width=15,
        height=15,
        scale=400,
        shadow_intensity = .75,
        sunangle = 250,
        #offset_edges=T,
        windowsize=c(4000,4000),
        zoom = .6,
        raytrace = TRUE,
        phi = 50,
        theta = 8)

render_snapshot("/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/denmark_swamp_maptest.png", clear=T)


# Use render_highquality for better rendering
render_highquality(
  filename = "/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/denmark_swamp_map_hq_render.png",
  samples = 256,
  clamp_value = 10,
  clear = TRUE,
  lightintensity = 1000,
)







########

# Define the plotting function with no frame or background
# 2. DEFINE THE PLOTTING FUNCTION WITH LOG TRANSFORMATION
get_denmark_map <- function(f) {
  # Get breaks and colors
  breaks_list <- get_breaks(f)
  vmin <- breaks_list$vmin
  vmax <- breaks_list$vmax
  breaks <- breaks_list$breaks
  cols2 <- get_colors()
  
  # Create the plot
  p <- ggplot(f) +
    geom_sf(aes(fill = val + 1), color = NA, size = 0) +  # Add offset to avoid log(0)
    scale_fill_gradientn(
      name = "Observations",
      colours = cols2,
      trans = "sqrt"  # Apply log10 transformation
    ) +
    guides(fill = guide_legend(
      direction = "horizontal",
      nrow = 1,  # Ensure legend is in one row
      keyheight = unit(5, units = "mm"),
      keywidth = unit(10, units = "mm"),  # Increase key width for clarity
      title.position = 'bottom',
      title.hjust = 0.5,
      label.hjust = 0.5,
      reverse = TRUE,
      label.position = "bottom"
    )) +
    coord_sf(crs = crsLONGLAT) +
    theme_minimal() + 
    theme(
      # Remove all text elements
      text = element_blank(),
      axis.line = element_blank(),
      axis.text = element_blank(),
      axis.ticks = element_blank(),
      axis.title = element_blank(),
      
      # Remove all grid lines
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      
      # Set the backgrounds to transparent or white as needed
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = NA),
      
      # Remove the panel border
      panel.border = element_blank()
    ) +
    labs(
      x = "", 
      y = NULL, 
      title = "Fungi Observations in The Kingdom of Denmark", 
      subtitle = "Aggregated by Hex Grid", 
      caption = "Data Source: GBIF.org (30 October 2024) GBIF Occurrence Download https://doi.org/10.15468/dl.2ngspp"
    )
  
  return(p)
}

# Generate the plot
p <- get_denmark_map(f) + theme(legend.position = "none")

p

# Render in rayshader without the flat frame or background
plot_gg(p,
        multicore = TRUE,
        width = 10,
        height = 10,
        scale = 300,
        shadow_intensity = 0.75,
        sunangle = 320,
        windowsize = c(4000, 3000),
        zoom = 0.5,
        raytrace = TRUE,
        phi = 70,      # Top-down view
        theta = 5,     # Direct view with no tilt
        flat_plot_render = FALSE  # Remove the flat 2D layer
)

render_snapshot("/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/denmark_swamp_map.png13", clear=T)


# Use render_highquality for better rendering
render_highquality(
  filename = "/Users/frederikreimert/Library/CloudStorage/OneDrive-DanmarksTekniskeUniversitet/Kandidat_DTU/2024E/02807_Computational_Tools_for_Data_Science/svampe_spot_finder/denmark_swamp_map14.png",
  samples = 256,
  clamp_value = 10,
  clear = TRUE,
  lightintensity = 1000
)

