
# This script uses the EPA public API to collect and clean data on
# Integrated Reporting (IR) to the EPA under the Clean Water Act
# Sections 303(d), 305(b) and 314. The primary cleaning operation is transforming
# the data from .json format to .csv, in addition to selecting only certain
# features of interest.
# 
# Note: this script only pulls assessments which resulted in a use support
# determination of 'Not Attaining.'
# 
# Related script: `pull_actions.R`.
# 
# Author: Ryan Treves
# Updated: 09/19/22

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
  
  # Biennial CWA 305(b) assessments started in 2002
  for (year in c('2002', '2004', '2006', '2008', '2010', '2012', '2014',
                 '2016', '2018', '2020', '2022')) {
    state_year_data <- tibble()
    # We want assessments that resulted in a use support determination of 'Not
    # Supporting'
    raw <- fromJSON(paste('https://attains.epa.gov/attains-public/api/assessments?useSupport=N&state=',
                          state, '&reportingCycle=', year, sep=""))
                           
    # If there exist IR5 assessments for the given reporting cycle and state
    if (raw$count != 0){
        
      # We're interested in information that is encoded into nested dataframes-
      # so we unnest them
      state_year_data <- unnest(unnest(unnest(raw$items, assessments, names_repair='universal'),
                                       useAttainments, names_repair='universal', keep_empty = T),
                                       parameters, names_repair='universal', keep_empty = T)
      state_year_data <- state_year_data %>% filter(state_year_data$useAttainmentCode == 'N')
      
      # In addition, some nested dataframes are mostly unneeded information, 
      # so we can extract the variables directly
      if (('assessmentMetadata' %in% colnames(state_year_data)) && 
          (typeof(state_year_data$assessmentMetadata) == 'list') &&
          (typeof(state_year_data$assessmentMetadata$assessmentActivity) == 'list')) {
          state_year_data$assessment_date <- state_year_data$assessmentMetadata$assessmentActivity$assessmentDate
        } else {
        state_year_data['assessment_date'] <- NA
      }
      
      if ((typeof(state_year_data$impairedWatersInformation) == 'list') &&
          (typeof(state_year_data$impairedWatersInformation$listingInformation) == 'list')) {
          state_year_data$cycle_first_listed <- state_year_data$impairedWatersInformation$listingInformation$cycleFirstListedText
          state_year_data$cycle_scheduled_for_TMDL <- state_year_data$impairedWatersInformation$listingInformation$cycleScheduledForTMDLText
          state_year_data$CWA303dPriorityRankingText <- state_year_data$impairedWatersInformation$listingInformation$CWA303dPriorityRankingText
        } else {
        state_year_data['cycle_first_listed'] <- NA
        state_year_data['cycle_scheduled_for_TMDL'] <- NA
        }
      
      # Collect information on associated actions
      if ('associatedActions' %in% colnames(state_year_data)) {
        state_year_data$associatedActions <- sapply(state_year_data$associatedActions, as.data.frame)
        state_year_data <- unnest(state_year_data, associatedActions, names_repair = 'universal', keep_empty=T)
        if (!('associatedActionIdentifier' %in% colnames(state_year_data))) {
          state_year_data['associatedActionIdentifier'] <- NA
        }
      } else {
        state_year_data['associatedActionIdentifier'] <- NA
      }
      
      
      # Create a state variable for convenience
      state_year_data$state_code <- state
      
      # Select down to variables of interest
      state_year_data <- select(state_year_data, any_of(c('state_code',
                                                   'organizationIdentifier',
                                                   'organizationTypeText',
                                                   'reportingCycleText',
                                                   'assessmentUnitIdentifier',
                                                   'useName',
                                                   'useAttainmentCode',
                                                   'epaIRCategory',
                                                   'associatedActionIdentifier',
                                                   'threatenedIndicator',
                                                   'parameterStatusName',
                                                   'parameterName',
                                                   'cycle_first_listed',
                                                   'cycleLastAssessedText',
                                                   'cycle_scheduled_for_TMDL',
                                                   'CWA303dPriorityRankingText',
                                                   'assessment_date')))
      
      state_data <- plyr::rbind.fill(state_data, state_year_data)
    }
  }
  write.csv(state_data, paste(state, '_NotSupporting_assessments.csv', sep=""))
  data <- plyr::rbind.fill(data, state_data)
  print(paste(state, 'done'))
}
write.csv(data, 'all_NotSupporting_assessments.csv')
