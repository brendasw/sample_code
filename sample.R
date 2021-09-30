library(readxl)
library(sp)
library(sf)
library(tidyverse)
library(data.table)
library(ggplot2)
library(ggiraph)
library(htmlwidgets)
#Set path
path <- "E:"
raw_file<-"imf-who-covid-19-vaccine-supply-tracker.xlsx"
df <- read_excel(paste(path,raw_file, sep="/"), sheet = "data", skip = 2)

#Create Heat Map for Secured Vaccine (% of population)
countries <- c("Afghanistan","Armenia","Azerbaijan","Georgia","Kazakhstan","Kyrgyz Republic","Pakistan","Tajikistan","Turkmenistan","Uzbekistan") 
iso3<-df[df$`Countries and areas` %in% countries, "ISO3"]
world <- sf::st_as_sf(rnaturalearth::countries110)
asia_df <- dplyr::filter(world, iso_a3 %in% iso3$ISO3) %>%
           dplyr::left_join(df %>% 
           dplyr::rename(iso_a3=`ISO3`,Secured.Vaccine=`Secured Vaccine (% of population)`),
           by = 'iso_a3') %>%
           st_transform(crs="+proj=laea +lon_0=18.984375")

asia_df.centers <- st_centroid(asia_df)
asia_df.spdf <- methods::as(asia_df, 'Spatial')
asia_df.spdf@data$id <- row.names(asia_df.spdf@data)
asia_df.tidy <- broom::tidy(asia_df.spdf)
asia_df.tidy <- dplyr::left_join(asia_df.tidy, asia_df.spdf@data, by='id')

#Create Plot as g
g <- ggplot(asia_df.tidy) +
  geom_polygon_interactive(
  color='black',
  aes(long, lat, group=group, fill=Secured.Vaccine,
        tooltip=sprintf("%s<br/>%s%s",sovereignt,round(Secured.Vaccine, digits = 2),"%"))) +
  hrbrthemes::theme_ipsum() +
  colormap::scale_fill_colormap(
  colormap=colormap::colormaps$jet, reverse = T) +
  labs(title='Secured Vaccine in Central and West Asia', subtitle='As % of Population',
       caption='Source: The IMF-WHO COVID-19 Vaccine Supply Tracker')

#Save to html
widgetframe::frameWidget(ggiraph(code=print(g)))
saveWidget(ggiraph(code=print(g)), 
           file=paste(path,"heat_map.html", sep="/"))

#Create Stacked bar chart 
asia<-df[df$`Countries and areas` %in% countries,]
asia<-setDT(asia)
col<-colnames(df)
m_asia<-melt(asia,measure.vars = col[-(1:18)],
             variable.name = "Sources",value.name = "% of population") 
m_asia$Sources<-str_extract(m_asia$Sources,"[^\\(]*")

p<-ggplot(data = m_asia,aes(`Countries and areas`, `% of population`, fill=Sources)) + 
   geom_col()+
   theme(axis.text.x = element_text(angle=15, vjust=1, hjust=1))+
   labs(title='Sources of Vaccine Supply', subtitle='As % of Population',
   x ="Central and West Asia", y = "% of population")

#Save to png
ggsave(paste(path,"bar_plot.png", sep="/"), height=4.5, width=8, units='in', plot=p)


