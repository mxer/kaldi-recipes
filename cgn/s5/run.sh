#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.


cgn=$GROUP_DIR/c/cgn

! ( utils/validate_data_dir.sh data/train && utils/validate_data_dir.sh data/test && utils/validate_data_dir.sh data/dev ) || local/cgn_data_prep.sh $cgn  || exit "Could not prep corpus";

