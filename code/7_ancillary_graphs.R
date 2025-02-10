

# load data ---------------------------------------------------------------

# Plot Directory
plot.dir <- './output/plots'


# Sales in Brazil, China, USA, EU
ev_sales2022 <- read_excel(file.path('./input', 'sales_2022.xlsx')) %>%
  arrange(Country, rev(Type)) %>%
  group_by(Country) %>%
  mutate(label_y = cumsum(Share)- 0.3 * Share,
         Share = round(Share, digits = 2),
         label_y = if_else(Country == 'Brazil' & Type == 'Hybrid', label_y+0.02, label_y)) %>%
  mutate(Share_lbl = Share,
         Share_lbl = if_else(Share < 0.02, NA, Share),
         Share_lbl = paste0(Share_lbl*100,"%"),
         Share_lbl = if_else(Share_lbl == "NA%", "", Share_lbl))
  

# Registration of New Vehicles Brazil
load(file.path('./tmp', '2_anfavea_registration.rda'))

# Sucateamento
exit <- read_csv2(file.path('./input', 'sucateamento_example.csv'))


# Fleet
load(file.path('./tmp', '3_compute_fleet.rda'))

# World and Brazilian Sales -----------------------------------------------

ev_sales2022 %>%
  ggplot(aes(fill=Type, y=Share, x=Country)) + 
  geom_col(width = 0.4) +
  ggtitle('EV Participation in Vehicle Sales, 2022') +
  theme_economist_white(gray_bg = F,horizontal = F) + scale_fill_wsj() +
  theme(axis.line=element_blank(),
        axis.text.y = element_blank(),
        axis.title.x =  element_blank()) +
  ylab("") + guides(fill=guide_legend(title= '')) +
  geom_text(aes(y = label_y, label = Share_lbl), vjust = 1.5, colour = "white",size=7) +
  scale_y_continuous(labels=scales::percent,) +
  labs(caption = 'Source: IEA (2023), Anfavea (2022)')
ggsave(filename = '7_1_ev_sales2022.pdf', width = 15, height = 10, path = plot.dir)



# Evolution of Brazilian Registration -------------------------------------

regis %>%
  filter(Year > 1960) %>%
  arrange(Year) %>%
  mutate(change = Registration/lag(Registration) - 1) %>%
  ggplot() +
  geom_col(aes(y=change, x=Year)) +
  geom_hline(aes(yintercept=0.074)) + 
  geom_hline(aes(yintercept=0.045)) +
  geom_text(aes(2021, 0.1,label = 'Avg 60-22: 7.4%', vjust = 1), size = 5.5) +
  geom_text(aes(2021, 0.044,label = 'Avg 90-22: 4.5%', vjust = 1), size = 5.5) +
  ggtitle('Car Registrations, Brazil', subtitle = 'Year-Over-Year Growth') +
  theme_economist_white(gray_bg = F, horizontal = F) + scale_color_wsj() +
  theme(axis.line =    element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank()) +
  labs(caption = 'Source: Anfavea (2023)')+
  scale_y_continuous(labels=scales::label_percent(), breaks = c(-0.4, -0.2,-0.1,0,0.1,0.2,0.4))
ggsave(filename = '7_2_brazil_growth_sales.pdf', width = 15, height = 10, path = plot.dir)


# Evolução Market Share no Brasil -----------------------------------------

shares_brasil <- regis %>%  
  mutate(across(starts_with('Registration'), ~ .x / Registration, .names = 'Shr{col}')) %>%
  select(c('Year', starts_with('Shr'))) %>%
  pivot_longer(cols = starts_with('ShrRegistration'), names_to = 'Fuel', values_to = 'Shr') %>%
  filter(Fuel != 'ShrRegistration') %>%
  mutate(Fuel = str_replace(Fuel, 'ShrRegistration', replacement = '')) %>%
  filter(Year >= 2015)

shares_brasil %>%
  ggplot(aes(fill=Fuel, y=Shr, x=Year)) + 
  geom_col(width = 0.4) +
  ggtitle('Light Vehicle Registrations, Brazil', 'Share of Powertrains, 2010-2022') +
  theme_economist_white(gray_bg = F,horizontal = F) + scale_fill_wsj() +
  ylab("") + guides(fill=guide_legend(title= '')) +
  scale_y_continuous(labels=scales::percent) +
  scale_x_continuous(breaks = c(2015:2022)) +
  theme(axis.title.x = element_blank()) +
  labs(caption = 'Source: Anfavea (2023)')
ggsave(filename = '7_4_brazil_registration_2015_2022.pdf', width = 15, height = 10, path = plot.dir)


shares_brasil %>%
  filter(Fuel %in% c('BEV', 'Hybrid')) %>%
  arrange(Year, rev(Fuel)) %>%
  group_by(Year) %>%
  mutate(Shr_lbl = Shr,
         Shr_lbl = paste0(round(Shr_lbl,3)*100, "%"),
         Shr_lbl = if_else(Year < 2021, '', Shr_lbl),
         label_y = if_else(Year >= 2021, cumsum(Shr), NA)) %>%
  ggplot(aes(fill=Fuel, y=Shr, x=Year)) + 
  geom_col(width = 0.4) +
  ggtitle('Light Vehicle Registrations, Brazil', 'Share of Powertrains, 2010-2022') +
  theme_economist_white(gray_bg = F,horizontal = T) + scale_fill_wsj() +
  ylab("") + guides(fill=guide_legend(title= '')) +
  scale_y_continuous(labels=scales::percent,) +
  scale_x_continuous(breaks = c(2015:2022)) +
  theme(axis.title.x = element_blank()) +
  geom_text(aes(y = label_y, label = Shr_lbl), vjust = 1.5, colour = "white",size=5) +
  labs(caption = 'Source: Anfavea (2023)')
ggsave(filename = '7_5_brazil_EVregistration_2015_2022.pdf', width = 15, height = 10, path = plot.dir)


# Data vis: sucateamento --------------------------------------------------

exit %>%
  ggplot(aes(y=Sucateamento, x=Age)) + 
  geom_line(linewidth = 0.75) +
  ggtitle('Curva de Sucateamento, Ciclo Otto', 'Sobrevivência da Frota') +
  theme_economist_white(gray_bg = F) + scale_fill_wsj() +
  ylab("") + guides(fill=guide_legend(title= '')) +
  scale_y_continuous(labels=scales::percent) +
  labs(caption = 'Source: COPPE/UFRJ') + scale_x_continuous(name ="Age")
ggsave(filename = '7_6_exit_example.pdf', width = 15, height = 10, path = plot.dir)


# Fleet -------------------------------------------------------------------

fleet <- regis_fleet %>%
  select(c('Year', !starts_with('Registration'))) %>%
  filter(Year > 1990) %>%
  rename('FleetModeled' = 'ModeledFleet',
         'FleetAnfavea' = 'AnfaveaFleet')


fleet %>%
  select(c('Year', 'FleetModeled', 'FleetAnfavea')) %>%
  pivot_longer(cols = c('FleetModeled', 'FleetAnfavea'), 
               names_to = 'Series', values_to = 'Fleet') %>%
  mutate(Series = str_replace(Series, 'Fleet', ''),
         Fleet = Fleet/10^6) %>%
  filter(Year < 2022) %>%
  ggplot(aes(x = Year, y = Fleet, group = Series, color = Series)) +
  geom_line(linewidth = 0.75) +
  geom_text(aes(x = 2022, y = 41.5, label = '41.5M'), vjust = 1.5, colour = "red",  size = 6) +
  geom_text(aes(x = 2022, y = 44.5, label = '43.6M'), vjust = 1.5, colour = "blue", size = 6) +
  ggtitle('Brazilian Fleet: Light Vehicles', 'in Millions') +
  theme_economist_white(gray_bg = F,horizontal = T) + scale_color_wsj('dem_rep') +
  ylab("") + guides(color=guide_legend(title= '')) + 
  scale_x_continuous(breaks = c(1990:2021)) +
  scale_y_continuous(expand= c(0, 0), limits = c(0,50)) +
  theme(axis.title.x = element_blank()) +
  labs(caption = 'Source: Anfavea (2023)')
ggsave(filename = '7_7_fleet_model.pdf', width = 15, height = 10, path = plot.dir)


