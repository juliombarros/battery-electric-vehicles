# ------------------------------------------------------------------------
# Creates dataset on registration of new vehicles using single ANFAVEA file
# (from Anfavea Time-series)
#
# Compares Anfavea BEV figures with ABVE figures.
# ------------------------------------------------------------------------


# files -------------------------------------------------------------------

regis_hist <- read_excel(path = file.path('./input', 'anfavea_registration_by_fuel.xlsx'))

abve <- read_delim(file.path('./input', 'abve_registration_bev.txt'), 
                  delim = ":", 
                  skip = 1, 
                  col_names = c('Year', 'RegistrationABVE'),n_max = 12) %>%
  as_tibble() %>%
  mutate(RegistrationABVE = str_remove(RegistrationABVE, "[.]")) %>%
  mutate(RegistrationABVE = as.numeric(RegistrationABVE))

# registration yearly files (from individual excel):
load(file.path('./tmp', '1_anfavea_registration_yearly_files.rda'))

# separate hybrid and bev -------------------------------------------------


# Updates to 2022
regis_update <- regis_hist %>%
  bind_rows(regis_yearly %>% filter(Year == 2022))

# Adds 2012-2022 info on Hybrid and BEV; 
# Adds ABEV Numbers
regis <- regis_update %>%
  select(!c('RegistrationHybrid', 'RegistrationBEV')) %>%
  left_join(regis_yearly %>% select(c('Year', 'RegistrationHybrid', 'RegistrationBEV'))) %>%
  left_join(abve) %>%
  mutate(RegistrationBEV = coalesce(RegistrationBEV, RegistrationABVE)) %>%
  mutate(RegistrationHybrid = coalesce(RegistrationHybrid, RegistrationElectric)) %>%
  select(c('Year', starts_with('Regis'))) %>%
  select(!c('RegistrationElectric', 'RegistrationABVE', 'Registration')) %>%
  mutate(across(everything(.), ~ replace_na(.x, 0))) %>%
  mutate(Registration = rowSums(select(.,starts_with("Registration"))))

# save --------------------------------------------------------------------

save(regis, file = file.path('./tmp', '2_anfavea_registration.rda'))

# end ---------------------------------------------------------------------