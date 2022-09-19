#!/bin/bash

# Select which version to launch depending on the environment
if [[ -z $DISPLAY ]] ; then
    attractplus-kms $@
else
    attractplus-x11 $@
fi
