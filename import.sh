#!/bin/bash

# Appeals

# Assessments

### Parcel boundaries ###
curl -X GET -G 'https://data.wprdc.org/datastore/dump/858bbc0f-b949-4e22-b4bb-1a78fef24afc' \
  --data-urlencode q= \
  --data-urlencode plain=False \
  --data-urlencode language=simplesc \
  --data-urlencode filters={} \
  --data-urlencode format=tsv \
  --data-urlencode fields=pin,wkt |
  sed '1d' |
  psql -q -d propertydb -c "COPY parcelboundaries (parcelid, wkt) FROM STDIN DELIMITER E'\t'"

# Convert to PostGIS format
psql -q -d propertydb -c "UPDATE parcelboundaries SET geom = ST_GeometryFromText(wkt);"

### Parcel centroids ###
curl -X GET -G 'https://data.wprdc.org/datastore/dump/adf1fd38-c374-4c4e-9094-5e53bd12419f' \
  --data-urlencode q= \
  --data-urlencode plain=False \
  --data-urlencode language=simplesc \
  --data-urlencode filters={} \
  --data-urlencode format=csv \
  --data-urlencode fields=PIN,Latitude,Longitude,MAPBLOCKLO |
  sed '1d' |
  psql -q -d propertydb -c "COPY parcelcentroids (parcelid, lat, lon, parcelmbl) FROM STDIN DELIMITER ','"

### Parcel delinquencies (Pittsburgh) ###
curl -X GET -G 'https://data.wprdc.org/datastore/dump/ed0d1550-c300-4114-865c-82dc7c23235b' \
  --data-urlencode q= \
  --data-urlencode plain=False \
  --data-urlencode language=simplesc \
  --data-urlencode filters={} \
  --data-urlencode format=csv \
  --data-urlencode fields=pin,prior_years,current_delq |
  sed '1d' |
  psql -q -d propertydb -c "COPY parceldelinquenciespgh (parcelid, prioryears, backtaxes) FROM STDIN DELIMITER ','"

### Pittsburgh-owned parcels ###
psql -q -d propertydb -c "\copy parceleproppgh (parcelid, parceltype, parcelstatus) FROM 'rtkl/db-properties-pgh-07122023.csv' CSV HEADER;"

### URA-owned parcels ###
psql -q -d propertydb -c "\copy parcelepropura (parcelid, parceltype, parcelstatus) FROM 'rtkl/db-properties-ura-07062023.csv' CSV HEADER;"

### Pittsburgh facilities ###
curl -X GET -G 'https://data.wprdc.org/datastore/dump/fbb50b02-2879-47cd-abea-ae697ec05170' \
  --data-urlencode q= \
  --data-urlencode plain=False \
  --data-urlencode language=simplesc \
  --data-urlencode filters={} \
  --data-urlencode format=tsv \
  --data-urlencode fields=parcel_id,name |
  sed '1d' |
  psql -q -d propertydb -c "COPY parcelfacilitiespgh (parcelmbl, name) FROM STDIN DELIMITER E'\t'"

# Fix numerous parcel IDs
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '5-S-97' WHERE name = 'Mount Washington Shelter House';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '13-K-314' WHERE name = 'Arlington Field Lights Building';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '173-L-39' WHERE name = 'Chadwick Recreation Center';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '13-E-16' WHERE name = 'Quarry Street Storage Shed';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '121-K-166' WHERE name = 'Morningside Crossing';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '1-M-150' WHERE name = '412 Blvd of the Allies';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '27-S-150-0-1' WHERE name = 'Schenley Park Ice Rink Chiller Building';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '7-C-226' WHERE name = 'Police Narcotics and Vice Warehouse';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '85-D-50' WHERE name = 'Mellon Park Scaife Building';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '125-L-237-0-1' WHERE name = 'Public Works 2nd Division Storage Area';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '85-D-50' WHERE name = '85-D-50-0-1'; -- Mellon Park"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '121-L-128' WHERE name = '1221-L-128';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '127-H-100-0-1' WHERE name = 'Frick Park Duffy Cabin';"
psql -q -d propertydb -c "UPDATE parcelfacilitiespgh SET parcelmbl = '122-L-50' WHERE name = 'Asphalt Plant Equipment Shelter';"

# Insert new facilities when spread over multiple parcels
psql -q -d propertydb -c "INSERT INTO parcelfacilitiespgh (parcelmbl, name) VALUES('173-L-40', 'Chadwick Recreation Center 1');"
psql -q -d propertydb -c "INSERT INTO parcelfacilitiespgh (parcelmbl, name) VALUES('173-L-163', 'Chadwick Recreation Center 2');"

### Parcel liens ###
curl -X GET -G 'https://data.wprdc.org/datastore/dump/d1e80180-5b2e-4dab-8ec3-be621628649e' \
  --data-urlencode q= \
  --data-urlencode plain=False \
  --data-urlencode language=simplesc \
  --data-urlencode filters={} \
  --data-urlencode format=csv \
  --data-urlencode fields=pin,number,total_amount |
  sed '1d' |
  psql -q -d propertydb -c "COPY parcelliens (parcelid, count, amount) FROM STDIN DELIMITER ','"

### Pittsburgh-owned parcel sales ###
psql -q -d propertydb -c "\copy parcelsalespgh (parcelid, status, applicant, date) FROM 'rtkl/db-sales-pgh-07052023.csv' CSV HEADER;"

# Parcel violations (Pittsburgh)
