#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.


spraakbanken_archive_dir=$GROUP_DIR/c/spraakbanken


! ( utils/validate_data_dir.sh data/train && utils/validate_data_dir.sh data/test ) || local/spr_se_data_prep.sh $spraakbanken_archive_dir  || exit "Could not prep corpus";
