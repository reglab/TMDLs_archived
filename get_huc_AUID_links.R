
# This script uses the EPA ArcGIS REST service to download a linkage table 
# between ATTAINS Assessment Unit IDs and their associated HUC-12 code.
# 
# Details on scraping this table: https://gispub.epa.gov/arcgis/rest/services/OW/ATTAINS_Assessment/MapServer/3 
# Metadata: https://edg.epa.gov/metadata/catalog/search/resource/details.page?uuid=%7B20F11BD0-05FA-4F36-868E-6530B8F2BAD6%7D 

# Related scripts: get_huc_npdes_permit_links.R
# 
# Author: Ryan Treves
# Date: 09/09/22

library(jsonlite)
library(tidyverse)

# Get list of acceptable OrgIDs from ATTAINS
orgIDs <- unique(fromJSON('https://attains.epa.gov/attains-public/api/domains?domainName=OrgStateCode')$context)

data <- tibble()

for (orgID in orgIDs) {
  # How many results will there be total for this orgID?
  count <- fromJSON(paste('https://gispub.epa.gov/arcgis/rest/services/OW/ATTAINS_Assessment/MapServer/3/query?where=OrganizationID=\'', orgID, '\'&outFields=assessmentunitidentifier,huc12&returnGeometry=false&returnCountOnly=true&f=json',
                          sep=''),
                    flatten=TRUE)$count
  
  # Get all results from the REST service, 2000 at a time
  orgID_data <- tibble()
  i <- 0
  while (i<count) {
    orgID_data_slice <- fromJSON(paste('https://gispub.epa.gov/arcgis/rest/services/OW/ATTAINS_Assessment/MapServer/3/query?where=OrganizationID=\'', orgID,'\'&outFields=assessmentunitidentifier,huc12&returnGeometry=false&resultOffset=',i, '&f=json', sep=''),
                                 flatten=TRUE)$features
    orgID_data <- rbind(orgID_data, orgID_data_slice)
    i <- i + 2000
  }
  data <- rbind(data, orgID_data)
}

# Write to disk
write.csv(distinct(data), 'huc_AUID_links.csv')
