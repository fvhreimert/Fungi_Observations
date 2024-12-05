# Final Project: 02807 - Computational Tools for Data Analysis

This repository contains the code used for the final project of the course **02807 - Computational Tools for Data Analysis**.

The dataset used for this project is too large to include directly in the GitHub repository, but it can be downloaded from the following link:

- **Dataset**: [GBIF Occurrence Download (30 October 2024)](https://doi.org/10.15468/dl.g6zcq2)

---

## Project Structure

### 1. **Frequent Itemsets**
The `frequent_itemsets` folder contains the script `get_frequent_itemsets_pyspark.py`, which is used to find the frequent itemsets from the dataset. This script links to a pickle file on the **HPC system** that is accessible to all users on the **HPC system**.

### 2. **Finding Mushrooms Within 100 Meters of Each Other**
The `Find_neighbours` folder contains two subfolders: **Parallel_core/** and **Single_core/**.

- **Single_core/**: 
  - The `Find_neighbors.jl` script is located here. It is written in **Julia** and finds mushrooms that are within 100 meters of each other using a single core.

- **Parallel_core/**: 
  - This folder contains two important files:
    - `args_find_neighbors.jl`: A Julia script for finding nearby mushrooms.
    - `run_script_parallel.sh`: A shell script that runs the `args_find_neighbors.jl` script in parallel using **4 cores** to speed up the process.

Both of these scripts use the file `/dtu/blackhole/19/155129/csv_without_duplicates_long_lat_family.csv`, which is created by the `Graphic_graph.ipynb` notebook but can also be found on the **DTU HPC system**.

### 3. **Creating the Graph and Running Clustering Algorithms**
The `Graphic_graph.ipynb` Jupyter notebook contains the code for creating the graph and applying clustering algorithms to the dataset. It also includes the code for finding mushrooms within 100 meters of each other using the first algorithm described in the project.

### 4. **Plots**
In the `plot` folder, you will find the code used to recreate many of the plots included in the project. These plots provide visual insights into the dataset and the results of various analyses.

---







