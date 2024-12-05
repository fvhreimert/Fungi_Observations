### This repository contains the code used for the final project of the course 02807 Computation Tools for Data Analysis. 

The dataset is too large to add in the github repository, but can be downloaded using this link:
GBIF.org (30 October 2024) GBIF Occurrence Download https://doi.org/10.15468/dl.g6zcq2

# Frequent itemsets
The frequent_itemsets folder contains get_frequent_itemsets_pyspark.py which will find the frequent_itemsets.
The file links to a "pickle file" on the HPC-system which everyone has the right to access.

# Constructing the network
The NetworkConstruction folder contains two folders Parallel_core/ and Single_core/
Inside Single_core is the Julia script Find_neighborhs.jl which will find neighbours which are under 100 meters away using 1 core
Inside Parallel_core is a Julia script, args_find_neighborhs.jl and a script called run_script_parallel.sh. The script run_script_parallel.sh will run args_find_neighborhs.jl in parallel using 4 cores and find neighbours under 100 meters away.



