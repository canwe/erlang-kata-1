#!/bin/bash

erl -pz _build/default/lib/epmdpxy/ebin -eval 'epmdpxy:start(43690)'

