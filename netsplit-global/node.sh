#!/bin/bash

ERL_EPMD_PORT=43690 erl -pz _build/default/lib/*/ebin -name $1 -setcookie cluster

