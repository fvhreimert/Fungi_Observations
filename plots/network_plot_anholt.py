from matplotlib.colors import BoundaryNorm
import networkx as nx
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import matplotlib as mpl
import osmnx as ox
from shapely.geometry import Point
from matplotlib.cm import viridis
from pyproj import Transformer
from matplotlib.colors import Normalize
from matplotlib.cm import ScalarMappable
import geopandas as gpd
from matplotlib.lines import Line2D
from matplotlib.colors import BoundaryNorm
import pandas as pd
import pickle
import numpy as np
import json
import folium
from folium.plugins import MarkerCluster

#-|-# Copilot has helped to parts of the code #-|-#

# path = data_path
df_anholt = pd.read_csv(path)

# Coordinates of Anholt
lat_center = 56.712174
lon_center = 11.576959

# Create a Folium map centered on Anholt
m = folium.Map(location=[lat_center, lon_center], zoom_start=13)

# Initialize MarkerCluster
marker_cluster = MarkerCluster().add_to(m)

# Add markers to the cluster
for idx, row in df_anholt.iterrows():
    folium.Marker(
        location=[row['decimalLatitude'], row['decimalLongitude']],
        popup=f"gbifID: {row['gbifID']}",
        icon=folium.Icon(color='green', icon='info-sign')
    ).add_to(marker_cluster)

m

################## GEOPANDAS

# Create a GeoDataFrame with Point geometries
gdf_observations = gpd.GeoDataFrame(
    df_anholt,
    geometry=gpd.points_from_xy(df_anholt.decimalLongitude, df_anholt.decimalLatitude),
    crs="EPSG:4326"
)

# Get Anholt boundary from OpenStreetMap
anholt = ox.geocode_to_gdf('Anholt, Denmark')

# Ensure CRS matches
anholt = anholt.to_crs(gdf_observations.crs)

# Initialize the plot
fig, ax = plt.subplots(figsize=(10, 10))

# Plot Anholt
anholt.plot(ax=ax, color='lightblue', edgecolor='black', alpha=0.5, label='Anholt')

# Plot observations
gdf_observations.plot(ax=ax, markersize=50, color='green', alpha=0.6, label='Fungi Observations')

# Customize the plot
plt.title("Fungi Observations on Anholt")
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.legend()
plt.show()
