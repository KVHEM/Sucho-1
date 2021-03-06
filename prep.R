require(rgdal)
require(rmapshaper)
require(maptools)
require(data.table)
require(stringr)
require(dplyr)

#1 Prostorová data
setwd()
#Loading
#--------------------
povodi_0 <- readOGR('data/geo/E_HEIS$UPV_HLGP#P2$wm.shp', 'E_HEIS$UPV_HLGP#P2$wm')
reky_0 <- readOGR('data/geo/E_ISVS$UPOV_R.shp', 'E_ISVS$UPOV_R')
jezera_0 <- readOGR('data/geo/E_ISVS$UPOV_J.shp', 'E_ISVS$UPOV_J')
nadrze_0 <- readOGR('data/geo/nadrze.shp')

#Preparation of data
#--------------------
povodi_0 <- spTransform(povodi_0, CRS("+init=epsg:4326"))
povodi <- ms_simplify(povodi_0, keep_shapes = TRUE, keep = 0.05)
#--------------------
proj4string(reky_0) <- CRS("+title=Krovak JTSK +proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813975277778 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56 +no_defs <>")
reky_0 <- spTransform(reky_0, CRS("+init=epsg:4326"))
reky <- ms_simplify(reky_0, keep_shapes = TRUE, keep = 0.10)
#--------------------
proj4string(jezera_0) <- CRS("+title=Krovak JTSK +proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813975277778 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56 +no_defs <>")
jezera_0 <- spTransform(jezera_0, CRS("+init=epsg:4326"))
jezera <- ms_simplify(jezera_0, keep_shapes = TRUE, keep = 0.05)

proj4string(nadrze_0) <- CRS("+title=Krovak JTSK +proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813975277778 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +units=m +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56 +no_defs <>")
nadrze <- spTransform(nadrze_0, CRS("+init=epsg:4326"))

kraje_0 <- readOGR('data/geo/admin/kraje.shp')
kraje <- spTransform(kraje_0, CRS("+init=epsg:4326"))
kraje <- ms_simplify(kraje_0, keep_shapes = TRUE, keep = 0.10)

a <- kraje_0$NAZEV
a[1] <- "Ústecký"
kraje_0$NAZEV <- kraje_0$NK
kraje_0$NAZEV <- a


okresy_0 <- readOGR('data/geo/admin/okresy.shp')
okresy_0 <- spTransform(okresy_0, CRS("+init=epsg:4326"))
okresy <- ms_simplify(okresy_0, keep_shapes = TRUE, keep = 0.10)

#Saving
#--------------------
#writeSpatialShape(povodi,"data/prep/povodi")
# writeSpatialShape(reky,"data/prep/reky")
# writeSpatialShape(jezera,"data/prep/jezera")

writeOGR(povodi, "data/prep", "povodi", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(reky, "data/prep", "reky", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(jezera, "data/prep", "jezera", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(nadrze, "data/prep", "nadrze", driver="ESRI Shapefile", encoding  = "UTF-8")
#writeOGR(kraje, "data/prep", "kraje", driver="ESRI Shapefile", encoding  = "UTF-8")
writeOGR(okresy, "data/prep", "okresy", driver="ESRI Shapefile", encoding  = "UTF-8")

kraje <- readOGR("data/prep/kraje.shp")
a <- as.character(kraje$NAZEV)
a[2] <- "Ústecký"
kraje <- ms_simplify(kraje, keep_shapes = TRUE, keep = 0.10)
kraje$NAZEV <- a 

writeSpatialShape(kraje,"data/prep/kraje")

povodi_III_0 <- readOGR('data/geo/A08_Povodi_III.shp')
povodi_III_0 <- spTransform(povodi_III_0, CRS("+init=epsg:4326"))
povodi_III <- ms_simplify(povodi_III_0, keep_shapes = TRUE, keep = 0.10)

writeSpatialShape(povodi_III,"data/prep/povodi_III")

# leaflet() %>%
#   addTiles() %>% 
#   addPolygons(data=kraje, color="#000000", fillColor = "#595959", 
#               weight = 2, opacity = 1,
#               popup = kraje$NAZEV)

#2 Měsiční bilance

#Loading
#--------------------
r = readRDS('BER_0010.rds')

#Preparation of data
#--------------------
i ='BER_0010.rds'
M = list()
for (i in dir()){
  r = readRDS(i)
  mr = melt(r, id.vars = 'DTM')
  m1 = mr[variable!='T', .(value = sum(value)), by = .(year(DTM), month(DTM), variable)]
  m2 = mr[variable=='T', .(value = mean(value)), by = .(year(DTM), month(DTM), variable)]
  m = rbind(m1,m2)
  m[, DTM:=as.Date(paste(year, month, 1, sep = '-'))]
  M[[length(M)+1]] = m
}

names(M) = gsub('\\.rds', '', dir())
BM = rbindlist(M, idcol = 'UPOV_ID')

#Saving
#--------------------
# setwd("./data")
# BM <- readRDS('data/mbilan/bilan_month - puvodni.rds')

mesice <- c("Leden","Únor","Březen","Duben","Květen","Červen",
            "Červenec","Srpen","Září","Říjen","Listopad","Prosinec")

seasons <- data.frame(month = c(1:12), seasons = c("Zima", "Zima", "Jaro", "Jaro", "Jaro", "Leto", "Leto",
                                                   "Leto","Podzim", "Podzim", "Podzim", "Zima"))

BM <- BM %>% left_join(seasons, by="month") 
BM$month2 <- as.factor(BM$month)
levels(BM$month2) <- mesice

BM <- BM %>% group_by(UPOV_ID, year, variable) %>% mutate(annual.avg = mean(value)) %>% ungroup

BM <- BM %>% group_by(UPOV_ID, variable) %>% mutate(mean_ep = mean(value)) %>%  ungroup

# quarter <- data.frame(month=c(1:12), quarter = rep(1:4, each=3)) 
# BM <- BM %>% left_join(quarter, by="month")
# 
# BM <- BM %>% group_by(UPOV_ID, year, quarter, variable) %>% mutate(quarterly.avg = mean(value)) %>% ungroup

BM.long <- dcast(BM, month+year+UPOV_ID+DTM~variable)
BM.long$m <- as.factor(BM.long$month)
levels(BM.long$m) <- mesice

saveRDS(BM, 'data/mbilan/bilan_month.rds')
saveRDS(BM.long, 'data/mbilan/bilan_month_long.rds')

#3 Denní průtoky
#--------------------
setwd("..")

#Loading
#--------------------

# getCPLConfigOption("data/chmu/156_stanic.shp")
# setCPLConfigOption("data/chmu/156_stanic.shp", NULL)
# 
# a <- stanice_0$NAZEV_TOK
# write.csv(a, "a.csv")

stanice_0 <- readOGR("data/chmu/156_stanic.shp")
seznam.st <- read.csv('data/chmu/156_stanic_seznam.csv',encoding = 'UTF-8', header = TRUE, sep = ";", 
                      colClasses = c("factor", "character", "character", "character", "character"))

QD <- read.table('data/chmu/QD_156_stanic.txt',encoding = 'UTF-8', header = TRUE, sep=',', 
                 colClasses = c("factor", "character", "numeric"), col.names = c("DBCN", "DTM", "value"))

#Preparation of data
#--------------------
colnames(seznam.st)[2] <- "NAZEV.STANICE"
colnames(seznam.st)[4] <- "OBDOBI.S.DATY.DENNICH.PRUTOKU"

stanice <- spTransform(stanice_0, CRS("+init=epsg:4326"))

QD$DTM <- as.Date(QD$DTM, format = "%d.%m.%Y")
QD <- merge(seznam.st,QD, by="DBCN")

#Saving
#--------------------
saveRDS(QD, "QD.rds")
writeOGR(stanice, "data/prep", "stanice", driver="ESRI Shapefile", encoding  = "UTF-8")


#4 uzivani_ocistene
#Loading
#--------------------
u <- read.csv('data/vuv/uzivani_utvary_06_16.csv',encoding = 'UTF-8', header = TRUE, sep = ";")
u <- readRDS('data/uzivani/79_15/uzivani.rds')
#Preparation of data
#--------------------

u <- u[complete.cases(X, Y)]
u$DTM <- as.character(u$DTM)

colnames(u)[1] <- "ICOC"
u = melt(u, id.vars = c("ICOC", "JEV", "CZ_NACE", "POVODI", "NAZEV", "ROCNI.MNOZSTVI.tis.m3", "POVOLENE.MNOZSTVI.ROK.tis.m3", "SOUR_X",	"SOUR_Y",	"UPOV_ID",	"HEIS_POZN", "ROK"
))

u$variable <- gsub("MVM*", "", u$variable)
u$value <- gsub(",", ".", u$value)

u$DTM <- paste0("01",str_sub(paste0("00",u$variable),-2,-1), u$ROK, sep="-")
u$DTM <- as.Date(u$DTM, format = "%d%m%Y")
u$value <- as.numeric(u$value)

colnames(u)[13] <- "MESIC"
colnames(u)[c(8,9)] <- c("X", "Y")
colnames(u)[5] <- "NAZICO"

u <- u[!is.na(u$X)|!is.na(u$Y),] #vynechani bodu s neznamymi souradnicemi 

#Saving
#--------------------
setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho")
saveRDS(u, "data/uzivani/06_16/uzivani_NA.rds") #obsahuje NA
saveRDS(u, 'data/uzivani/06_16/uzivani_na_rm.rds') #vynechane NA

### doplneni zaznamu od bodu se stejnym ICOC
u <- readRDS('data/uzivani/06_16/uzivani_NA.rds')

u$na <- as.numeric(is.na(u$X))
# u <- u %>% group_by(ICOC, JEV) %>% mutate(mean.na = mean(na))
u <- u %>% group_by(ICOC) %>% mutate(mean.X = mean(X, na.rm = T), mean.Y = mean(Y, na.rm = T)) %>% ungroup
u$X[is.na(u$X)] <- u$mean.X[is.na(u$X)]
u$Y[is.na(u$Y)] <- u$mean.Y[is.na(u$Y)]

u <- u[!is.na(u$X)|!is.na(u$Y),]

saveRDS(u, 'data/uzivani/06_16/uzivani_na_nahraz.rds') # NA nahrazene průměrem za ICOC

# #5 Denni data
# #--------------------
# 
# setwd("C:/Users/Irina/Disk Google/1_ČZU/Sucho/data/bilan")
# 
# d = dir()
# 
# R = list()
# for (i in d){
#   cat(i, '\n')
#   R[[i]] = readRDS(i)
# }
# 
# names(R) = gsub('\\.rds', '', names(R))  
# RR = rbindlist(R, idcol = 'UPOV_ID')
# 
# #Saving
# #--------------------
# saveRDS(RR, "C:/Users/Irina/Disk Google/1_ČZU/Sucho/data/bilan_day.rds")


#6 uzivani / UPOV_ID
#--------------------
require(rgeos)

povodi <- readOGR("data/prep/povodi.shp")
popis <- read.table('data/E_ISVS$UTV_POV.txt',encoding = 'UTF-8', header = TRUE, sep=';')
povodi <- sp::merge(povodi, popis, by='UPOV_ID')

u <- readRDS('data/uzivani/79_15/uzivani.rds')

u <- u[complete.cases(X, Y)]
xy <- SpatialPoints(u[, c("X", "Y")], proj4string = CRS("+init=epsg:2065"))
xy <- spTransform(xy, CRS("+init=epsg:4326") )

### 524, 525, 751, 752 - CHYBA 
# Error in createPolygonsComment(p) : 
# rgeos_PolyCreateComment: orphaned hole, cannot find containing polygon for hole at index 2
# In addition: Warning message:
#   In RGEOSBinPredFunc(spgeom1, spgeom2, byid, func) :
#   spgeom1 and spgeom2 have different proj4 strings
### 1112 1113 1114 1115 1116 1117 1118 1119 1120 1121
# Error in povodi[povodi$UPOV_ID == i, ] : NAs not permitted in row index
# In addition: There were 50 or more warnings (use warnings() to see the first 50)

pocitadlo <- 0

for (i in povodi$UPOV_ID) {
  kde <- gIntersects(povodi[povodi$UPOV_ID==i,], xy, byid = TRUE)
  u$UPOV_ID[kde[,1]] <- i
  pocitadlo <- pocitadlo+1
  print(paste(i, (pocitadlo/1121)*100, '%'))
}

 saveRDS(u, 'data/uzivani/79_15/uzivani_upovid.rds')
