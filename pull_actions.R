
# This script uses the EPA public API to collect and clean data on ections (e.g.,
# TMDLs, 4B Actions, Alternative Actions, Protection Approach Actions)
# related to  Integrated Reporting (IR) to the EPA under the Clean Water Act
# Sections 303(d), 305(b) and 314. The primary cleaning operation is transforming
# the data from .json format to .csv, in addition to selecting only certain
# features of interest.
# 
# Related script: `pull_IR5_assessments.R`.
# 
# Author: Ryan Treves
# Date: 08/15/22


library(tidyverse)
library(jsonlite)

# Note 'VI'= Virgin Islands, 'PR'= Puerto Rico, 'GU'= Guam
states <- c('AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'GU',
            'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME',
            'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY',
            'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN',
            'TX', 'UT', 'VT', 'VA', 'VI', 'WA', 'WV', 'WI', 'WY')

data <- tibble()
permit_data <- tibble()

for (state in states) {
  state_data <- tibble()
  state_permit_data <- tibble()
  
  # Pull actions from EPA API
  raw <- fromJSON(paste('https://attains.epa.gov/attains-public/api/actions?stateCode=', state, sep=""))
  
  # If actions exist for the given state
  if (raw$count != 0) {
    # We're interested in information that is encoded into nested dataframes-
    # so we unnest them
    state_data <- raw$items %>% unnest(actions, names_repair='universal') %>%
      unnest(associatedWaters, names_repair='universal') %>%
      unnest(specificWaters, names_repair='universal')
    
    # Deals with Missouri, actions with missing values for `parameters`
    if (state=='MO') {
      state_data$parameters <- sapply(state_data$parameters, as.data.frame)
    }
    state_data <- unnest(state_data, parameters, names_repair='universal')
    
    # Deals with actions with missing values for `associatedPollutants`
    if (state != 'OR') { # Issue with OR here
      state_data$associatedPollutants...13 <- sapply(state_data$associatedPollutants...13, as.data.frame)
    }
    state_data <- unnest(state_data, associatedPollutants...13, names_repair='universal')
    
    # If the state includes data on TMDL date
    if (typeof(state_data$TMDLReportDetails) == 'list') {
      state_data$TMDLDate <- state_data$TMDLReportDetails$TMDLDate
    } else {
      state_data['TMDLDate'] <- NA
    }
    
    # Create a state variable for convenience
    state_data$state_code <- state
    
    # Set aside data matching actionIDs to permits
    if ('permits' %in% colnames(state_data)) {
      state_permit_data <- select(state_data, c('actionIdentifier', 'permits'))
      if (state != 'PR') { # Issue here with PR data
        state_permit_data$permits <- sapply(state_permit_data$permits, as.data.frame)
      }
      state_permit_data <- unnest(state_permit_data, permits, names_repair='universal')
      state_permit_data <- select(state_permit_data, any_of(c('actionIdentifier', 'NPDESIdentifier')))
    }
    
    # Select variables of interest
    state_data <- select(state_data, any_of(c('organizationIdentifier',
                                             'organizationTypeText',
                                             'state_code',
                                             'actionIdentifier', 'actionTypeCode',
                                             'actionStatusCode', 'completionDate',
                                             'assessmentUnitIdentifier',
                                             'pollutantName',
                                             'pollutantSourceTypeCode',
                                             'explicitMarginofSafetyText',
                                             'implicitMarginofSafetyText',
                                             'TMDLEndPointText',
                                             'parameter', 'TMDLDate')))
    
    data <- rbind(data, state_data)
    permit_data <- rbind(permit_data, state_permit_data)
    print(paste(state, 'done'))
  }
}
write.csv(data, 'all_actions.csv')
write.csv(permit_data, 'all_actions_permit_data.csv')
