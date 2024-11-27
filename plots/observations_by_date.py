import pandas as pd
import pickle
import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns

#-|-# Copilot has helped to parts of the code #-|-#

path = "data_path."
df = pd.read_csv(path, delimiter = "\t", nrows = 10)


df = df[["gbifID", "year","month", "day", "dateIdentified"]]

# Set Seaborn style for a clean look
sns.set(style="whitegrid", context="talk", palette="colorblind")

# Create the plot
plt.figure(figsize=(12, 6))

# Plot with enhanced aesthetics
sns.lineplot(
    x=weekly_average_counts.index,
    y=weekly_average_counts.values,
    linewidth=2.5,
    color='#22A884FF',  # Choose a single, distinguishable color
    marker='o',         # Optional: add markers for data points
    markersize=6,
    label='Average Fungi Observations'
)

# Set labels with increased font size
plt.xlabel("Week of the Year", fontsize=14, weight='bold')
plt.ylabel("Average Number of Occurrences", fontsize=14, weight='bold')

# Set title with increased font size and bold weight
plt.title("Average Weekly Number of Fungi Observations Throughout the Year", fontsize=16, weight='bold')

# Customize x-axis ticks
plt.xticks(
    ticks=range(1, 53, 4),
    labels=[f"Week {i}" for i in range(1, 53, 4)],
    rotation=25,
    fontsize=12
)

# Customize y-axis ticks
plt.yticks(fontsize=12)

# Adjust grid for subtlety
plt.grid(True, which='both', linestyle='--', linewidth=0.5, alpha=0.7)

# Add legend if multiple lines are present
#plt.legend(title='', fontsize=12, loc='upper right')

# Tight layout for better spacing
plt.tight_layout()

# Save the figure with high resolution
plt.savefig("/dtu/blackhole/19/155129/Swamp_Network_Plots_Simple/average_weekly_fungi_observations.png", dpi=300)

# Display the plot
plt.show()