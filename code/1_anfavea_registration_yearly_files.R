# ------------------------------------------------------------------------
# Binds all anfavea licenciamento files into one single dataset
#
#
# ------------------------------------------------------------------------



# Read xl files -----------------------------------------------------------

anfavea_fls <- list.files(file.path('./input'),
           pattern = 'siteauto',
           full.names = T)

# fleet <- read_csv2(file.path('C:/Users/ASUS/Documents/psr/input','anfavea_fleet.csv')) %>%
#  rename('year' = `...1`) %>%
#  mutate(light_fleet = rowSums(select(.,c('automoveis','comerciais leves'))))

# function to extract time series from files ------------------------------

extract_anfavea <- function(fl) {
  read_excel(fl,
                        sheet = 'III. Licenciamento Combustível',
                        range = 'C6:P11') %>%
    rename('fuel' = `...1`,
           'cars' = 'Total Ano') %>%
    select('fuel', 'cars') %>%
    mutate(year = str_extract(fl,'20.[0-9]')) %>%
    filter(!is.na(cars)) %>%
    mutate(fuel = case_when(year < 2021 & fuel == 'Elétrico' ~ 'Híbrido',
                            year >= 2021 & fuel == 'Elétrico' ~ 'BEV',
                            TRUE ~ fuel))
}


# map function on files ---------------------------------------------------

regis_yearly <- map(anfavea_fls, extract_anfavea) %>%
  list_rbind() %>%
  pivot_wider(names_from = 'fuel',values_from = 'cars') %>%
  rename_with(tolower) %>%
  rename('hybrid' = 'híbrido',
         'flex'    = 'flex fuel',
         'gasoline' = 'gasolina') %>%
  mutate(year = as.numeric(year)) %>%
  rename_with(~ str_to_title(.x)) %>%
  rename_with(~ paste0("Registration",.x), !starts_with('Year')) %>%
  rename('RegistrationBEV' = 'RegistrationBev')



# save --------------------------------------------------------------------

save(regis_yearly, file = file.path('./tmp', '1_anfavea_registration_yearly_files.rda'))


# end ---------------------------------------------------------------------