#!/bin/bash
echo 'request to url '$URL 
curl -k -X POST -d 'client_id=che-public&username=admin&password=admin&grant_type=password' $URL
