rm -rf ./output/
mkdir output

target_home_dir=$(pwd)
docker cp ff3335db191e:$target_home_dir/output/ ./output/
