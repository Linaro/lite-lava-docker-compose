#!/bin/bash

# Usage: ./monitor-images.sh <your LAVA identity>
#
#   This script monitors the 'test-images' directory for any file that is
#   dropped into it. It assumes the directory layout is
#   test-images/<device-type>, and upon detecting a new file, uses the
#   corresponding job template in job-templates/lava_<device-type>.job
#   to submit the job with the provided LAVA identity.
#
#   '<test_image>' in the template is automatically substituted with the
#   actual path to the test image.

contrib_dir=`dirname $0`
dir=test-images
template_dir=job-templates

cd $contrib_dir/..

inotifywait -r -m "$dir" -e close_write --format '%w%f' |
    while IFS=' ' read -r fname
    do
        IFS='/'
        read -ra path <<< "$fname"
        template="$template_dir"/lava_"${path[1]}".job
        if [ ! -f "$template" ]
        then
            #if no template found for the device-type, do nothing
            continue
        fi

        echo "Using template for device type ${path[1]}:"
        echo "    $template"

        # Replace <test_image> with actual path to test image
        sed_cmd=s/\<test_image\>/"file:\/\/\/${fname//\//\\\/}"/g

        tmp_file=$(mktemp)
        echo "Submitting job for $fname"
        [ -f "$fname" ] && sed "$sed_cmd" "$template" > "$tmp_file" && lavacli -i $1 jobs submit "$tmp_file" && rm "$tmp_file"
    done
