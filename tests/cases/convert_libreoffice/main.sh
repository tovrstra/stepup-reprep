#!/usr/bin/env -S bash -x
# Exit on first error and cleanup.
set -e
trap 'kill $(pgrep -g $$ | grep -v $$) > /dev/null 2> /dev/null || :' EXIT
xargs rm -rvf < .gitignore

# Run the example
export SOURCE_DATE_EPOCH="315532800"
stepup -w 1 plan.py & # > current_stdout.txt &

# Get the graph after completion of the pending steps.
python3 - << EOD
from stepup.core.interact import *
wait()
graph("current_graph")
EOD

# Reproducibility test
mv slide.pdf slide1.pdf
python3 - << EOD
from stepup.core.interact import *
from stepup.reprep.make_manifest import write_manifest
watch_delete("slide.pdf")
run()
join()
write_manifest("reproducibility_manifest_skip.txt", ["slide.pdf", "slide1.pdf"])
EOD

# Wait for background processes, if any.
wait $(jobs -p)

# Check files that are expected to be present and/or missing.
[[ -f plan.py ]] || exit -1
[[ -f slide.odp ]] || exit -1
[[ -f slide.pdf ]] || exit -1
[[ -f slide1.pdf ]] || exit -1
[[ -f reproducibility_manifest_skip.txt ]] || exit -1
