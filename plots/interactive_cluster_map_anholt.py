import plotly.graph_objects as go
from matplotlib.colors import Normalize
from matplotlib.cm import ScalarMappable
from matplotlib.colors import to_hex
from plotly.offline import plot
import matplotlib.colors as mcolors
import matplotlib.cm as cm

#-|-# Copilot has helped to parts of the code #-|-#

# Load Anholt data
df_anholt = pd.read_csv(path1)

# Load Lasse data
with open(path2) as file:
    df_lasse = pickle.load(file)

    # Ensure the first column of df_lasse is named or accessed correctly
filtered_df_lasse = df_lasse[df_lasse[0].isin(df_anholt["gbifID"])]

# Create the NetworkX graph
G = nx.Graph()

# Add nodes with positions
for _, row in df_anholt.iterrows():
    G.add_node(row['gbifID'], pos=(row['decimalLongitude'], row['decimalLatitude']))

# Create the set to track added edges
added_edges = set()

# Loop through each row in filtered_df_lasse to add edges
for _, row in filtered_df_lasse.iterrows():
    node1, node2 = row[0], row[1]  # Assume these are the columns with node pairs
    
    # Ensure the edge is in a consistent order
    edge = tuple(sorted((node1, node2)))
    
    # Only add the edge if it hasn't been added yet
    if edge not in added_edges:
        G.add_edge(node1, node2)
        added_edges.add(edge)  # Track this edge as added

        # Get positions of nodes
pos = nx.get_node_attributes(G, 'pos')

# Separate the positions into x and y coordinates
x_nodes = [pos[k][0] for k in G.nodes()]
y_nodes = [pos[k][1] for k in G.nodes()]

edge_x = []
edge_y = []

for edge in G.edges():
    x0, y0 = pos[edge[0]]
    x1, y1 = pos[edge[1]]
    edge_x += [x0, x1, None]
    edge_y += [y0, y1, None]

edge_trace = go.Scatter(
    x=edge_x,
    y=edge_y,
    line=dict(width=1, color='#888'),
    hoverinfo='none',
    mode='lines'
)

node_trace = go.Scatter(
    x=x_nodes,
    y=y_nodes,
    mode='markers+text',
    text=[str(node) for node in G.nodes()],
    textposition="top center",
    hoverinfo='text',
    marker=dict(
        showscale=True,
        colorscale='YlGnBu',
        size=10,
        color=[],  # Will assign colors based on some attribute if needed
        colorbar=dict(
            thickness=15,
            title='Node Connections',
            xanchor='left',
            titleside='right'
        ),
        line_width=2
    )
)

# Assign colors based on the number of connections (degree)
node_adjacencies = []
for node in G.nodes():
    node_adjacencies.append(len(list(G.neighbors(node))))
node_trace.marker.color = node_adjacencies

# Create the figure
fig = go.Figure(data=[edge_trace, node_trace],
             layout=go.Layout(
                title='<br>Interactive Network Graph',
                titlefont_size=16,
                showlegend=False,
                hovermode='closest',
                margin=dict(b=20,l=5,r=5,t=40),
                annotations=[ dict(
                    text="",
                    showarrow=False,
                    xref="paper", yref="paper") ],
                xaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
                yaxis=dict(showgrid=False, zeroline=False, showticklabels=False))
                )

# Display the plot in the browser
fig.write_html("/dtu/blackhole/19/155129/Swamp_Network_Plots_Simple/lasse_network_graph2.html")