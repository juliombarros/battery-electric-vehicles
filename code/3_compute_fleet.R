# ------------------------------------------------------------------------
# Computes fleet on 2021
# 
#
# ------------------------------------------------------------------------



# input -------------------------------------------------------------------

# Registration time-series
load(file.path('./tmp', '2_anfavea_registration.rda'))

# Fleet time-series
anfavea_fleet <- read_csv2(file.path('./input','anfavea_fleet.csv')) %>%
  rename('Year' = `...1`) %>%
  mutate(AnfaveaFleet = rowSums(select(.,c('automoveis','comerciais leves')))) %>%
  select(c('Year', 'AnfaveaFleet'))


# compute exit function ---------------------------------------------------

# regis <- regis %>% select(c('Year', 'Registration'))


sucateamento_otto <- function(yr, registration) {
   
  age  <- max(yr) - yr
  exit <- exp(-exp(1.798-0.137*age))
  shr_available <- 1 - exit
  
  shr_available * registration
  
}

sucateamento_diesel <- function(yr, registration) {
  
  age  <- max(yr) - yr
  exit <- (1/(1+exp(0.17*(age - 15.3)))) + (1/(1+exp(0.17*(age + 15.3))))
  shr_available <- 1 - exit
  
  shr_available * registration
  
}

# Yearly dataframes in a list:
regis_ls <- map(.x = regis$Year, 
                 ~ regis %>% filter(Year <= .x))

# Pass exit function to compute each year's contribution to net of fleet
yearly_net <- map(.x = regis_ls, 
                  ~ .x %>% mutate( FleetGasoline = sucateamento_otto(Year, RegistrationGasoline),
                                   FleetEthanol  = sucateamento_otto(Year, RegistrationEthanol),
                                   FleetFlex     = sucateamento_otto(Year, RegistrationFlex),
                                   FleetDiesel   = sucateamento_otto(Year, RegistrationDiesel),
                                   FleetHybrid   = sucateamento_otto(Year, RegistrationHybrid),
                                   FleetBEV      = sucateamento_otto(Year, RegistrationBEV)))

# Summation for each year
yearly_fleet <- map_df(.x = yearly_net, 
                    ~ .x %>% 
                      mutate(across(starts_with("Fleet"), ~ sum(.x))) %>% 
                      filter(Year == max(Year)) %>%
                      select(c(Year, starts_with("Fleet")))) %>%
                mutate(ModeledFleet = rowSums(select(.,starts_with("Fleet"))))

# Add information of fleet to register;
# Add ANFAVEA Fleet information
regis_fleet <- regis %>% inner_join(yearly_fleet) %>%
  left_join(anfavea_fleet)

# save --------------------------------------------------------------------

save(regis_fleet, file = file.path('./tmp', '3_compute_fleet.rda'))

write_excel_csv2(x = regis_fleet, file = file.path('./tmp', '3_compute_fleet.csv'))

# end ---------------------------------------------------------------------