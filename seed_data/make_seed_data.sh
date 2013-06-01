#!/bin/bash

# ---------------------------------------------------------------------------
# Just an example on how to take the original IpToCountry CIDR data from
# http://software77.net/geo-ip/ and make it compatible with the CSV code
# ---------------------------------------------------------------------------

# Create a file with just the pieces we need for IP->Country from the original file
egrep -v '^#' IpToCountry.2013-05-27.csv | cut -d, -f1,2,6 > addresses.csv

# Create a file with just the pieces we need for ISO3 country data from the original file
egrep -v '^#' IpToCountry.2013-05-27.csv | cut -d, -f6,7 | sort | uniq > countries.csv

