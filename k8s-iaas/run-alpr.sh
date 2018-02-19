#!/bin/bash

for i in $(ls /data/openalpr-data); do
  IMAGE_NAME="${JOB_NAME}"-$(echo $i | cut -f1 -d".")
  echo "processing ${i} on $(hostname) "
  alpr -c eu -j /data/openalpr-data/${i} > /data/openalpr-logs/"${IMAGE_NAME}".json
done


