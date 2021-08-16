#!/bin/bash

for f in site-packages/*
do
    dir=$(basename $f)
    rm -rf "lib/python*/site-packages/${f}"
    mv "site-packages/${f}" lib/python*/site-packages
done
