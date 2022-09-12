
# This script uses the EPA ArcGIS REST service to download a linkage table 
# between NPDES Permit IDs and their associated HUC-12 code. According
# to the metadata, this layer is current as of 2016.
# 
# Details on scraping this table: https://watersgeo.epa.gov/arcgis/rest/services/OWRAD_NP21/NPDES_NP21/MapServer/0
# Metadata: https://edg.epa.gov/metadata/catalog/search/resource/details.page?uuid=%7B091FC504-8762-8E7F-DCD7-513F648BC5B5%7D 

# Related scripts: get_huc_AUID_links.R
# 
# Author: Ryan Treves
# Date: 09/09/22

library(jsonlite)
library(tidyverse)

# Note 'VI'= Virgin Islands, 'PR'= Puerto Rico
states <- c('AL', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
            'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME',
            'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN',
            'TX', 'UT', 'VT', 'VA', 'VI', 'WA', 'WV', 'WI', 'WY')

# Evidently, data from Alaska is missing from this feature layer (count=0).
# missing_states <- c('AK')

data <- tibble()

for (state in states) {
  # How many results will there be total for this state?
  count <- fromJSON(paste('https://watersgeo.epa.gov/arcgis/rest/services/OWRAD_NP21/NPDES_NP21/MapServer/0/query?where=GeogState=\'', state, '\'&outFields=Source_FeatureID,WBD_HUC12&returnGeometry=false&returnCountOnly=true&f=json', sep=''))$count
  
  # Get all results from the REST service, 1000 at a time
  state_data <- tibble()
  i <- 0
  while (i<count) {
    state_data_slice <- fromJSON(paste('https://watersgeo.epa.gov/arcgis/rest/services/OWRAD_NP21/NPDES_NP21/MapServer/0/query?where=GeogState=\'', state, '\'&outFields=Source_FeatureID,WBD_HUC12&returnGeometry=false&resultOffset=', i, '&f=json', sep=''), flatten=TRUE)
    state_data <- rbind(state_data, state_data_slice$features)
    i <- i + 1000
  }
  # NPDES permit ID is first 9 characters of SOURCE_FEATUREID
  state_data['npdes_permit_id'] <- lapply(state_data['attributes.SOURCE_FEATUREID'], FUN= function(x) substr(x, start=1, stop=9))
  data <- rbind(data, state_data)
}

# Write to disk
write.csv(data, 'huc_npdes_permit_links.csv')
