#!/bin/bash

echo "Running load_data.sh..."
/docker-entrypoint-initdb.d/load_data.sh
