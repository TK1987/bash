#!/bin/bash
cat /dev/urandom |tr -dc '[:graph:]'|fold -w 100|head -n 30
