#
# Name: exhaustive_sketch_sampling.sh
#
# Exhaustive sketch sampling experiment
#   for showing that sketch can sample log(V) spanning forests.
#

if [[ $# -lt 6 ]]; then
  echo "ERROR: Invalid Arguments!"
  echo "USAGE: exec_dir datasets_dir results_dir workers readers num_trials seed"
  echo "----------------------------------------------------------------"
  echo "exec_dir:              Directory where the executable is placed"
  echo "datasets_dir:          Directory where datasets are placed"
  echo "results_dir:           Directory where csv file should be placed"
  echo "workers:               Number of graph workers"
  echo "readers:               Number of graph readers"
  echo "num_trials:            Number of trials"
  echo "seed:                  Sketch Seed (Optinal. Default to random seed)"
  exit 1
fi

exec_dir=$1
datasets_dir=$2
result_dir=$3
workers=$4
readers=$5
num_trials=$6

if [[ -n "$7" ]]; then
  seed="$7"
else
  seed=""
fi

# Table of default_sample for each dataset
declare -A default_sample_table=(
  [kron_13_stream_binary]=18
  [kron_15_stream_binary]=21
  [kron_16_stream_binary]=22
  [kron_17_stream_binary]=23
  [ktree_13_2048_stream_binary_shuffled]=18
  [ktree_15_8192_stream_binary_shuffled]=21
  [ktree_16_16384_stream_binary_shuffled]=22
  [ktree_17_32768_stream_binary_shuffled]=23
  [ca_citeseer_stream_binary]=24
  [google_plus_stream_binary]=23
  [web_uk_stream_binary]=23)

# Datasets
kron_graphs=("kron_13_stream_binary" "kron_15_stream_binary"
             "kron_16_stream_binary" "kron_17_stream_binary")

sparse_graphs=("ca_citeseer_stream_binary" "google_plus_stream_binary"
               "web_uk_stream_binary") # Excluding p2p and rec_amazon because |V| too low

ktree_graphs=("ktree_13_2048_stream_binary_shuffled" 
              "ktree_15_8192_stream_binary_shuffled"
              "ktree_16_16384_stream_binary_shuffled" 
              "ktree_17_32768_stream_binary_shuffled")

out_file=runtime_results.csv

for stream_name in "${kron_graphs[@]}"
do
  > ${out_file}
  echo "size,samples" > ${out_file}
  ${exec_dir}/spanning_forest_extract ${datasets_dir}/kron/${stream_name} $workers $readers $num_trials ${default_sample_table[$stream_name]} $seed
  mv ${out_file} $result_dir/exhaustive_${stream_name}.csv
done

for stream_name in "${sparse_graphs[@]}"
do
  > ${out_file}
  echo "size,samples" > ${out_file}
  ${exec_dir}/spanning_forest_extract ${datasets_dir}/real_world/${stream_name} $workers $readers $num_trials ${default_sample_table[$stream_name]} $seed
  mv ${out_file} $result_dir/exhaustive_${stream_name}.csv
done

for stream_name in "${ktree_graphs[@]}"
do
  > ${out_file}
  echo "size,samples" > ${out_file}
  ${exec_dir}/spanning_forest_extract ${datasets_dir}/ktree/${stream_name} $workers $readers $num_trials ${default_sample_table[$stream_name]} $seed
  mv ${out_file} $result_dir/exhaustive_${stream_name}.csv
done

# Merge results
awk -F, 'NR==1 {print; next} FNR==1 {next} {sum[$1]+=$2} END {for (size in sum) print size "," sum[size]}' $result_dir/exhaustive_*_stream_binary*.csv | awk 'NR==1; NR>1 {print | "sort -g"}' > $result_dir/exhaustive_sketch_sampling.csv
