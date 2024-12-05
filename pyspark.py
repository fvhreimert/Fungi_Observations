# Important considerations
# Each item can only appear once in each "transcation", therefore
# seeing the same famly of fungi in the same transcation multiple times
# does only count as one

import pickle
import pandas as pd
from collections import defaultdict
import numpy as np
from pyspark.sql import SparkSession
from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    IntegerType,
    ArrayType,
    TimestampType,
)
from pyspark.ml.fpm import FPGrowth

# Load the dictionary from the pickle file
with open("/dtu/blackhole/19/155129/LASSE_OFFICIAL_EDGE_DATASET.pkl", "rb") as file:
    swamp_dict_tmp = pickle.load(file)
df = swamp_dict_tmp

# Create a defaultdict where each value is a list
swamp_dict = defaultdict(list)

# Load in the data
for from_, to_ in zip(df[0], df[1]):
    if from_ != np.nan and to_ != np.nan:
        if from_ != "NaN" and to_ != "NaN":
            swamp_dict[from_].append(to_)


# Set spark configuation
conf = (
    SparkConf()
    .setAppName("UsingMoreCores")
    .setMaster("local[*]")
    .set("spark.executor.cores", "32")
    # .set("spark.driver.memory", "1000")
    .set("spark.executor.instances", "1")  # Set 2 executors
)

# Initialize Spark session with custom configuration
spark = SparkSession.builder.config(conf=conf).getOrCreate()

# create dict to transform id to family
metadata = "/zhome/fa/f/155129/blackhole/csv_without_duplicates_long_lat_family.csv"
metadf = pd.read_csv(metadata)
id_fam = {
    id: fam
    for fam, id in zip(metadf["family"], metadf["gbifID"])
    if fam != "NaN" and id != "NaN"
}

# Setting dict to correct dataformat, and adding all in each cluster
# Additionally transform id to fam
tmp_swamp_r = [
    (key, list(set([id_fam[x] for x in item] + [id_fam[key]])))
    for key, item in swamp_dict.items()
]


# Removing nans
swamp_r = []
for key, lis in tmp_swamp_r:
    new_lis = []
    for l in lis:
        if l == l:
            new_lis.append(l)
    if len(new_lis) > 0:
        swamp_r.append((key, new_lis))


schema = StructType(
    [
        StructField("id", StringType(), True),
        StructField("items", ArrayType(StringType()), True),
    ]
)

sparkdf = spark.createDataFrame(swamp_r, schema=schema)
fpGrowth = FPGrowth(itemsCol="items", minSupport=0.25, minConfidence=0.2)
model = fpGrowth.fit(sparkdf)

model.freqItemsets.write.parquet(
    "/dtu/blackhole/19/155129/FREQUENT_ITEMSET_DATA/frequent_itemsets.parquet"
)

model.associationRules.write.parquet(
    "/dtu/blackhole/19/155129/FREQUENT_ITEMSET_DATA/association_rules.parquet"
)  # pickle.dump(association_df, open("/dtu/blackhole/19/155129/FREQUENT_ITEMSET_DATA/association_rules.pkl","wb"))

model.transform(sparkdf).write.parquet(
    "/dtu/blackhole/19/155129/FREQUENT_ITEMSET_DATA/prediction.parquet"
)

