
import pandas as pd
import warnings

# Suppress warning messages
warnings.filterwarnings('ignore')
pd.options.display.max_columns = 200
pd.options.display.max_rows = 2000


def get_limits():
    # Set states
    states = ['AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS',
              'KY_pre-2010', 'KY_2010-2019', 'KY_post-2019', 'LA', 'MA',
              'MD', 'ME', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE',
              'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH_pre-2010', 'OH_post-2010', 'OK', 'OR', 'PA', 'RI', 'SC',
              'SD', 'TN', 'TX','UT','VT', 'VA', 'WA', 'WV_pre-2010', 'WV_2010-2015', 'WV_2015-2018', 'WV_2018-2020',
              'WV_post-2020', 'WI','WY']
    for state in states:
        state_limits = pd.read_csv(
            '/Users/rtreves/Documents/RegLab/python_projects/dmr_permit_limit_changes/dmr_data/' + state + '_dmrs.csv',
            parse_dates=['limit_begin_date'],
            date_parser=lambda t: pd.to_datetime(t, errors='coerce'))
        state_limits = state_limits[['npdes_permit_id', 'perm_feature_nmbr', 'parameter_desc',
                                     'limit_value_type_code', 'statistical_base_code', 'limit_begin_date']].drop_duplicates()
        state_limits.to_csv('/Users/rtreves/Documents/RegLab/python_projects/dmr_permit_limit_changes/dmr_data/' +
                            state + '_limit_dates.csv')
        print(state + ' Done')
        state_limits = None
    return


def main():
    get_limits()


if __name__ == '__main__':
    main()
