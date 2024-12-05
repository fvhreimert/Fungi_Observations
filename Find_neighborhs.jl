
function distance_fn(x1, y1, x2, y2)
  return haversine((x1, y1), (x2, y2)) # default radius is earth -- 
end

function compare_x(array, extra_array, to_compare, i)
  our_point = (array[to_compare], extra_array[to_compare])
  other_point = (array[i], extra_array[to_compare])
  return haversine(our_point, other_point) # default radius is earth -- 
end

function compare_y(array, extra_array, to_compare, i)
  our_point = (extra_array[to_compare], array[to_compare])
  other_point = (extra_array[to_compare], array[i])
  return haversine(our_point, other_point) # default radius is earth -- 
end


function get_vals_in_range(array, to_compare, threshold, fn, extra_array)
  """
  Given a sorted array go from the index given in to_compare to the left and right
  and return all values until distance caluclated by fn is larger than the input threshold
  """
  under_threshold_index = Set(Int64[])

  # Going right and colleting items
  for i in 1+to_compare:length(array)  
    distance = fn(array, extra_array, to_compare, i)
    println(i)
    if distance > threshold
      break
    end
    push!(under_threshold_index, i)
  end

  # Going left
  for i in reverse(1: to_compare -1)
    println(i)
    distance = fn(array, extra_array, to_compare, i)
    if distance > threshold
      break
    end
    push!(under_threshold_index, i)
  end

  return under_threshold_index
end

function main(arg1, arg2)
df = CSV.read("/dtu/blackhole/19/155129/csv_without_duplicates_long_lat_family.csv", DataFrame)

dropmissing!(df, [:decimalLatitude, :decimalLongitude])



# Sort by x and extract columns
df_by_x = sort(df, [:decimalLatitude])
df_by_x.index = 1:nrow(df_by_x)
x_sortedforx = df_by_x[:,:decimalLatitude]
y_sortedforx =  df_by_x[:,:decimalLongitude]
name_sortedforx =  df_by_x[:,:gbifID]

# And sort the subset for y and get values out
df_by_y = sort(df_by_x, [:decimalLongitude])
subset_df = df_by_y
x_sortedfory = subset_df[:,:decimalLatitude]
y_sortedfory =  subset_df[:,:decimalLongitude]
name_sortedfory =  subset_df[:,:gbifID]

index_map = Dict(df_by_y.index[i] => i for i in 1:size(df_by_y, 1))
index_map_y_x = Dict(i => df_by_y.index[i]  for i in 1:size(df_by_y, 1))

threshold = 100 # in meters

len_xfory = length(x_sortedforx)
for index_to_compare in 1:len_xfory 
#for index_to_compare in arg1:arg2 
  i = index_to_compare
  index_to_compare_y = index_map[index_to_compare]

  name_target = name_sortedforx[index_to_compare]

  # Get all indexes which are posibile w.r.t to x
  under_threshold_index_x = get_vals_in_range(x_sortedforx, index_to_compare, threshold, compare_x, y_sortedforx)
  # Add our own
  push!(under_threshold_index_x,index_to_compare)

  under_threshold_index_y = get_vals_in_range(y_sortedfory, index_to_compare_y, threshold, compare_y, x_sortedfory)
  
  index_array_y = [index_map[i] for i in under_threshold_index_x]
  under_threshold_index_y =  intersect(under_threshold_index_y, index_array_y)



  # Calculate output for relevant, and pretty print it
  for index in under_threshold_index_y
    # Calculate distance
    distance = distance_fn(x_sortedfory[index_to_compare_y], y_sortedfory[index_to_compare_y], x_sortedfory[index], y_sortedfory[index])

    # Only print values if under threshold
    if distance < threshold
      println(name_sortedfory[index_to_compare_y], " , ", name_sortedfory[index], " , ", distance, " , ", i)
    end
  end

  end
end

using Distances
using CSV, DataFrames
main(parse(Int, ARGS[1]), parse(Int, ARGS[2]))

