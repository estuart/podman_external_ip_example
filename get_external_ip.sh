#!/bin/bash

# Get the IP address of a specific interface (e.g., eth0)
ip -o -4 addr show eth0 | awk '{print $4}' | cut -d/ -f1
