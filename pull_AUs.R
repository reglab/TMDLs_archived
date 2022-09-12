
# This script uses the EPA public API to collect and clean data on
# Integrated Reporting (IR) to the EPA under the Clean Water Act
# Sections 303(d), 305(b) and 314. Specifically, this script collects a list
# of assessment units nationally. The primary cleaning operation is transforming
# the data from .json format to .csv, in addition to selecting only certain
# features of interest.
# 
# Related scripts: `pull_actions.R`, `pull_assessments.R`.
# 
# Author: Ryan Treves
# Updated: 09/11/22

library(jsonlite)
library(tidyr)
library(dplyr)
library(plyr)

# Note 'VI'= Virgin Islands, 'PR'= Puerto Rico
states <- c('AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
            'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME',
            'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN',
            'TX', 'UT', 'VT', 'VA', 'VI', 'WA', 'WV', 'WI', 'WY')

data <- tibble()

for (state in states) {
  state_data <- tibble()
  
  raw <- fromJSON(paste('https://attains.epa.gov/attains-public/api/assessmentUnits?&stateCode=',
                 state, sep=""), flatten=TRUE)
                           
  # If there exist assessment units in the given state
  if (raw$count != 0){
    
    # We're interested in information that is encoded into nested dataframes-
    # so we unnest them
    state_data <- unnest(raw$items, assessmentUnits, names_repair='universal', keep_empty=T)
    state_data <- unnest(state_data, waterTypes, names_repair='universal', keep_empty=T)
      
    # Select down to variables of interest
    state_data <- select(state_data, any_of(c("assessmentUnitIdentifier",
                                              "assessmentUnitName",
                                              "locationDescriptionText",
                                              "agencyCode",
                                              "stateCode",
                                              "statusIndicator",         
                                              "waterTypeCode",
                                              "waterSizeNumber",
                                              "unitsCode",               
                                              "useClass.useClassCode",
                                              "useClass.useClassName")))
      
  }
  data <- plyr::rbind.fill(data, state_data)
  print(paste(state, 'done'))
}
write.csv(data, 'all_AUs.csv')
