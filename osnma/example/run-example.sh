#!/bin/sh

# Quick example to see that the project is installed and working properly

data=$(realpath ./galrawinav-270923.sbf)
pubk=$(realpath ./osnma-key-aug23.pem)

cd ../app
./osnma-cli $@ \
	-i $data \
	-k $pubk
