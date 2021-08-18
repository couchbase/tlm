#!/bin/bash

for f in site-packages/*
do
    dir=$(basename $f)
    rm -rf lib/python*/site-packages/"${dir}"
    mv "site-packages/${dir}" lib/python*/"site-packages"
done
