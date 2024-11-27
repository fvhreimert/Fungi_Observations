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

#-|-# Copilot has helped to parts of the code #-|-#

mpl.rcParams['figure.dpi'] = 300


# path1 = path to points on anholt
# path2 = path to edges between nodes

# Load Anholt data
df_anholt = pd.read_csv(path1)

# Load Lasse data
with open(path2) as file:
    df_lasse = pickle.load(file)

# Define the constant node size
constant_node_size = 10

# Create the NetworkX graph
G = nx.Graph()

# Add nodes with family attribute
for _, row in df_anholt.iterrows():
    G.add_node(row['gbifID'], class_left=row['class_left'])

# Add edges without duplicates
added_edges = set()
for _, row in filtered_df_lasse.iterrows():
    node1, node2 = row[0], row[1]  # Assuming columns 0 and 1 have node pairs
    edge = tuple(sorted((node1, node2)))
    if edge not in added_edges:
        G.add_edge(node1, node2)
        added_edges.add(edge)

# Define color mapping based on 'family' attribute
class_lefts = list(df_anholt['class_left'].unique())
class_left_to_color = {class_left: i for i, class_left in enumerate(class_lefts)}

# Set color map and normalize colors
cmap = plt.get_cmap('tab20') if num_classes <= 20 else plt.get_cmap('hsv')
norm = Normalize(vmin=0, vmax=len(class_lefts) - 1)
node_colors = [cmap(norm(class_left_to_color[G.nodes[node]['class_left']])) for node in G.nodes()]

# Set up spring layout with increased spacing between nodes
pos = nx.spring_layout(G, k=10 * 1 / (np.sqrt(len(G.nodes()))), iterations = 100)  # Adjust k to spread nodes more

# Create the plot with dynamic layout
fig, ax = plt.subplots(figsize=(7, 6))

# Draw edges with consistent styling
nx.draw_networkx_edges(
    G, 
    pos=pos, 
    ax=ax, 
    alpha=0.1, 
    width=0.5, 
    edge_color='gray'
)

# Draw nodes with constant size and family-based color
nx.draw_networkx_nodes(
    G, 
    pos=pos, 
    ax=ax, 
    node_size=constant_node_size, 
    node_color=node_colors, 
    alpha=1, 
    linewidths=0, 
    edgecolors='none'
)

# Add title
plt.title("Anholt Island Fungi Observation Graph", fontsize=16, fontweight='bold')

# Set discrete color normalization
norm = BoundaryNorm(range(len(class_lefts) + 1), cmap.N)

# Update color bar with reduced size and padding
sm = ScalarMappable(cmap=cmap, norm=norm)
cbar = plt.colorbar(sm, ax=ax, fraction=0.02, pad=0.02)  # Reduced fraction and pad
cbar.set_ticks(np.arange(len(class_lefts)) + 0.5)  # Offset for centering
cbar.set_ticklabels(class_lefts)
cbar.ax.tick_params(labelsize=8)  # Smaller tick label size for compactness

# Remove axes
plt.axis('off')
plt.tight_layout()

plt.show()
