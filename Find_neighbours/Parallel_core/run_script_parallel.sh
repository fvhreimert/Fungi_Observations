mkdir output_distance
parallel --will-cite --jobs 4 'julialauncher test_algo.jl {2} {1} > output_distance/{2}_{1}.csv' \
  ::: 1 200001 400001 600001 800001 \
  :::+ 200000 400000 600000 948994
