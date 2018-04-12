#
#  Skript to graphicaly Plot results from Agrammon
#  to plot annual results
#
#
#  BjE, 9. July 2008
#
##############

# Global Parameters
resultFile <- "result_2003.txt";                     # result File as Input for displaying Graphics
titel <- paste(resultFile);
Titel <- paste("Input file: ", titel, "");

# read Inputfile
farm <- read.table(resultFile, sep="|", skip=0, strip.white=TRUE, header=TRUE);

#plotPdf <- 1

#if(plotPdf){
#  pdf("result.pdf",width=11.75,height=8.25);
#   pdf("result_2003_test_x.pdf",width=8.25,height=11.75);
#   par(omi=0.39737007878*c(1,2.5,1,1));
#   par(pty="s")

#}else{
#}

# table of colors
colGrazing           <-  "#33CCCC";            # "#EEEE00"
colYard              <-  "#FFFF99";            # "#FFF68F" 
colHousing           <-  "#FFFF00";            # "#FFFF00"
colProduction        <-  "#FFFF00";
colStorage           <-  "#FF0000";            # "#CD661D" "#EE9A49"             
colApplication       <-  "#660066";            # "#008B00"
colRemainApplication <-  "#008000";            # "#00CD00" 
colRemainPasture     <-  "#00FF00";            # "#00FF00"

colors               <- c(colGrazing, colYard,  colHousing,  colStorage, colApplication, colRemainApplication, colRemainPasture);
colorsemission       <- c(colProduction, colStorage, colApplication);

colDairyCow  <- "#F5DEB3";
colCattle    <- "#8B4726";
colPigs      <- "#FF69B4";
colOther     <- "#00CD00";
colPoultry   <- "#FFD700";

colorsAnimal <- c(colDairyCow, colCattle, colPigs, colOther, colPoultry);

# matrix layout
layout(matrix(c(1,2,3,4,5,5),3,2,byrow=TRUE));

# Global Variables
totalStorage            <- farm$Value[farm$Module=="Storage" & farm$Variable=="nh3_nstorage"];
totalStorageKt          <- totalStorage / 1000000;
totalStorageKT          <- zapsmall(totalStorageKt, digits=3);

totalApplication        <- farm$Value[farm$Module=="Application" & farm$Variable=="nh3_napplication"];
totalApplicationKt      <- totalApplication / 1000000;
totalApplicationKT      <- zapsmall(totalApplicationKt, digits=3);

totalExcretion          <- farm$Value[farm$Module=="Production" & farm$Variable=="n_excretion"];
totalExcretionKt        <- totalExcretion / 1000000;
totalExcretionKT        <- zapsmall(totalExcretionKt, digits=3);

totalProduction         <- (farm$Value[farm$Modul=="Production" & farm$Variable=="nh3_nhousing"]+
                            farm$Value[farm$Modul=="Production" & farm$Variable=="nh3_nyard"]+
                            farm$Value[farm$Modul=="Production" & farm$Variable=="nh3_ngrazing"]
                            );
totalProductionKt       <- totalProduction / 1000000;
totalProductionKT       <- zapsmall(totalProductionKt, digits=3);

totalEmission           <- (totalProduction + totalStorage + totalApplication);
totalEmissionKt         <- totalEmission / 1000000;
totalEmissionKT         <- zapsmall(totalEmissionKt, digits=3);

AnimalCategories        <- c("DairyCow",          #Dairy Cows
                             "Heifers1yr", "Heifers2yr", "Heifers3y", "Beefcattle", "Fatteningcalves", "PreBcalves", "SuckCows", # Cattle
                              "DrySows", "NursSows", "FatPigs", "Piglets", "Boars", # Pig
                             "HoLw3yr", "HoUp3yr", "Mules", "Asses", "Goats", "Sheep", "Msheep", # Other
                             "Layers", "Growers", "Broilers", "Turkeys", "OPoultry" # Poultry
                             );

##  Farm Facts
#  Housing types: TODO
#  HousingTypeDairyCow TODO
#  HousingTypeCattle TODO
#  HousingTypePigs TODO
#  Storage: TODO
#  Cover type: TODO
#  pig/cattle manure: TODO

#  Application:
dj <- c(farm$Value[farm$Module=="Application::Liquid::Ctech" & farm$Variable=="share_deep_injection"]);
if (dj != 0.0){
  DJ <- paste("ApplicationLiquid_ShareDeepInj: ", dj, "");
}else{
  DJ <- paste();
};

sj <- c(farm$Value[farm$Module=="Application::Liquid::Ctech" & farm$Variable=="share_shallow_injection"]);
if (sj != 0.0){
  SJ <- paste("ApplicationLiquid_ShareShallowInj: ", sj, "");
}else{
  SJ <- paste();
};

ts <- c(farm$Value[farm$Module=="Application::Liquid::Ctech" & farm$Variable=="share_trailing_shoe"]);
if (ts != 0.0){
   TS <- paste("ApplicationLiquid_ShareTrailShoe: ", ts, "");
}else{
   TS <- paste();
};

th <- c(farm$Value[farm$Module=="Application::Liquid::Ctech" & farm$Variable=="share_trailing_hose"]);
if (th != 0.0){
  TH <- paste("ApplicationLiquid_ShareTrailHose: ", th, "");
}else{
  TH <- paste()
};

plot(0,0, type="n", axes=FALSE, main="Farm facts", xlab="", ylab="");
text.leg <- c(Titel, "HousingTypeDairyCow: ", "HousingTypeCattle: ", "HousingTypePig: ", "Storage: ", "Application: ", DJ, SJ, TS, TH);
legend(-1.0, 1, text.leg, cex=1, bty="n");
 

## Pi Chart with shares of Excretion per Animal Category
excretionShare <-  list();
excretionShare$DairyCow       <- farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Cattle         <- (farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Cattle[Heifers2yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Cattle[Heifers3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Cattle[Beefcattle]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Cattle[Fatteningcalves]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Cattle[PreBeefcalves]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Cattle[SucklingCows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion 
                                  );
excretionShare$Pigs           <- (farm$Value[farm$Module=="Production::Pig[DrySows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Pig[NursingSows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Pig[FatteningPigs]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Pig[Piglets]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Pig[Boars]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion
                                  );
excretionShare$Other          <- (farm$Value[farm$Module=="Production::Other[HorsesLw3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Other[HorsesUp3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  #farm$Value[farm$Module=="Production::Other[Mules]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Other[Asses]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Other[Goats]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Other[Sheep]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Other[Milksheep]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion
                                  );
excretionShare$Poultry        <- (farm$Value[farm$Module=="Production::Poultry[Layers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Poultry[Growers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Poultry[Broilers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Poultry[Turkeys]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion +
                                  farm$Value[farm$Module=="Production::Poultry[OtherPoultry]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion
                                  );
as.list(excretionShare);

exDairy   <- (excretionShare$DairyCow * 100);
ExDairy   <- zapsmall(exDairy, digits=2);

exCattle  <- (excretionShare$Cattle * 100);
ExCattle  <- zapsmall(exCattle, digits=2);

exPigs    <- (excretionShare$Pigs * 100);
ExPigs    <- zapsmall(exPigs, digits=2);

exOther   <- (excretionShare$Other * 100);
ExOther   <- zapsmall(exOther, digits=2);

exPoultry <- (excretionShare$Poultry * 100);
ExPoultry <- zapsmall(exPoultry, digits=2);

ext      <- c(ExDairy, ExCattle, ExPigs, ExOther, ExPoultry)
text.leg <- c("DairyCow", "Cattle", "Pigs", "Other", "Poultry")


pie(x=unlist(excretionShare),
    labels=ext,
    col=colorsAnimal,
    radius = 0.75,
    main="Share of N excretion [%]",
    sub=paste("Absolut N excretion: ", totalExcretionKT, " ", "kt N/ yr")
    );
legend("topright", text.leg, cex=0.8, pch=19, box.lty=3, col=colorsAnimal);


# Share of excretion per animal category in detail
excretionDetailShare <-  list();
excretionShare$DairyCow       <- farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;

excretionShare$Heifers1yr     <- (farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Heifers2yr     <- (farm$Value[farm$Module=="Production::Cattle[Heifers2yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Heifers3yr     <- (farm$Value[farm$Module=="Production::Cattle[Heifers3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Beefcattle     <- (farm$Value[farm$Module=="Production::Cattle[Beefcattle]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Fatteningcalves     <- (farm$Value[farm$Module=="Production::Cattle[Fatteningcalves]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$PreBeefcalves  <- (farm$Value[farm$Module=="Production::Cattle[PreBeefcalves]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$SucklingCows   <- (farm$Value[farm$Module=="Production::Cattle[SucklingCows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);

excretionShare$DrySows       <- (farm$Value[farm$Module=="Production::Pig[DrySows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$NursingSows   <- (farm$Value[farm$Module=="Production::Pig[NursingSows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$FatteningPigs <- (farm$Value[farm$Module=="Production::Pig[FatteningPigs]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Piglets       <- (farm$Value[farm$Module=="Production::Pig[Piglets]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Boars         <- (farm$Value[farm$Module=="Production::Pig[Boars]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);

excretionShare$HorsesLw3yr    <- (farm$Value[farm$Module=="Production::Other[HorsesLw3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$HorsesUp3yr    <- (farm$Value[farm$Module=="Production::Other[HorsesUp3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Mules          <- (farm$Value[farm$Module=="Production::Other[Mules]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Asses          <- (farm$Value[farm$Module=="Production::Other[Asses]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Goats          <- (farm$Value[farm$Module=="Production::Other[Goats]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Sheep          <- (farm$Value[farm$Module=="Production::Other[Sheep]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Milksheep      <- (farm$Value[farm$Module=="Production::Other[Milksheep]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
                              
excretionShare$Layers        <- (farm$Value[farm$Module=="Production::Poultry[Layers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Growers       <- ( farm$Value[farm$Module=="Production::Poultry[Growers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Broilers      <- ( farm$Value[farm$Module=="Production::Poultry[Broilers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$Turkeys       <- (farm$Value[farm$Module=="Production::Poultry[Turkeys]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);
excretionShare$OtherPoultry  <- (farm$Value[farm$Module=="Production::Poultry[OtherPoultry]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion);

as.list(excretionDetailShare);


## Pi Chart with shares of Emissions per Animal Category
emissionShare <-  list();
emissionShare$Production      <- (totalProduction /  totalEmission);
emissionShare$Storage         <- (totalStorage / totalEmission);
emissionShare$Application     <- (totalApplication /  totalEmission);
as.list(emissionShare);

eP <- (emissionShare$Production * 100)
EP <- zapsmall(eP, digits=3)
eS <- (emissionShare$Storage * 100)
ES <- zapsmall(eS, digits=3)
eA <- (emissionShare$Application * 100)
EA <- zapsmall(eA, digits=3)
et <- c(EP, ES, EA)

text.leg <- c("Production", "Storage", "Application");

pie(x=unlist(emissionShare),
    labels = et,
    col = colorsemission,
    radius = 0.75,
    main = "Share of NH3 emission [%]",
    sub=paste("Absolut N emission: ", totalEmissionKT, " ", "kt N/ yr")
    );
legend("topright", text.leg, cex=0.8, pch=19, box.lty=3, col = colorsemission);


## Bar Plot Total Emissions and Application
total <- c( farm$Value[farm$Module=="Production" & farm$Variable=="nh3_ngrazing"],
            farm$Value[farm$Module=="Production" & farm$Variable=="nh3_nyard"],
            farm$Value[farm$Module=="Production" & farm$Variable=="nh3_nhousing"],
            farm$Value[farm$Module=="Storage" & farm$Variable=="nh3_nstorage"],
            farm$Value[farm$Module=="Application" & farm$Variable=="nh3_napplication"],
            farm$Value[farm$Module=="Application" & farm$Variable=="n_out_application"],
            farm$Value[farm$Module=="Production" & farm$Variable=="n_remain_pasture"]
          );
nremainout <- c(farm$Value[farm$Module=="Application" & farm$Variable=="n_out_application"] +
                farm$Value[farm$Module=="Production" & farm$Variable=="n_remain_pasture"]
                );
nRemainout <- nremainout / 1000000;
nRemainOut <- zapsmall(nRemainout, digits=3);

barplot(cbind(total),
        names.arg=c("Total farm"),
        ylim=c(0,sum(total,na.rm=TRUE)*1.1),
        xlim=c(0,2),
        ylab="kg N/ yr",
        col=colors,
        width=0.5,
        main="Total N: NH3 emission & remaining N",
        sub=paste("N remain outdoor: ", nRemainOut, " ", "kt N/ yr"));
text.leg <- c("Grazing NH3","Yard NH3", "Housing NH3","Storage NH3", "Application NH3", "N out Appl.", "N rem. pasture");
legend("topright", text.leg, cex=0.8, pch=19, box.lty=3, col=colors);


## Bar Plot Animal Categories
emission <-  list();
emission$DairyCow             <- c( farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$DairyCow,
                                    totalApplication * excretionShare$DairyCow
                                  );
emission$Heifers1yr           <- c( farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$Heifers1yr,
                                    totalApplication * excretionShare$Heifers1yr
                                  );
emission$Heifers2yr           <- c( farm$Value[farm$Module=="Production::Cattle[Heifers2yr]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers2yr]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers2yr]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$Heifers2yr,
                                    totalApplication * excretionShare$Heifers2yr
                                  );
emission$Heifers3yr           <- c(farm$Value[farm$Module=="Production::Cattle[Heifers3yr]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers3yr]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers3yr]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$Heifers3yr,
                                    totalApplication * excretionShare$Heifers3yr
                                  );
emission$Beefcattle           <- c(farm$Value[farm$Module=="Production::Cattle[Beefcattle]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Beefcattle]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Beefcattle]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$Beefcattle,
                                    totalApplication * excretionShare$Beefcattle
                                    );
emission$Fatteningcalves           <- c(farm$Value[farm$Module=="Production::Cattle[Fatteningcalves]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Fatteningcalves]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Fatteningcalves]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$Fatteningcalves,
                                    totalApplication * excretionShare$Fatteningcalves
                                    );
emission$PreBeefcalves        <- c(farm$Value[farm$Module=="Production::Cattle[PreBeefcalves]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[PreBeefcalves]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[PreBeefcalves]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$PreBeefcalves,
                                    totalApplication * excretionShare$PreBeefcalves
                                   );
emission$SucklingCows         <- c(farm$Value[farm$Module=="Production::Cattle[SucklingCows]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[SucklingCows]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[SucklingCows]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$SucklingCows,
                                    totalApplication * excretionShare$SucklingCows
                                   );

emission$DrySows              <- c(farm$Value[farm$Module=="Production::Pig[DrySows]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Pig[DrySows]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$DrySows,
                                    totalApplication * excretionShare$DrySows
                                   );
emission$NursingSows          <- c(farm$Value[farm$Module=="Production::Pig[NursingSows]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Pig[NursingSows]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$NursingSows,
                                    totalApplication * excretionShare$NursingSows
                                   );
emission$FatteningPigs        <- c(farm$Value[farm$Module=="Production::Pig[FatteningPigs]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Pig[FatteningPigs]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$FatteningPigs,
                                    totalApplication * excretionShare$FatteningPigs
                                   );
emission$Piglets              <- c(farm$Value[farm$Module=="Production::Pig[Piglets]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Pig[Piglets]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Piglets,
                                    totalApplication * excretionShare$Piglets
                                   );
emission$Boars                <- c(farm$Value[farm$Module=="Production::Pig[Boars]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Pig[Boars]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Boars,
                                    totalApplication * excretionShare$Boars
                                   );

emission$HorsesLw3yr          <- c(farm$Value[farm$Module=="Production::Other[HorsesLw3yr]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Other[HorsesLw3yr]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$HorsesLw3yr,
                                    totalApplication * excretionShare$HorsesLw3yr
                                   );
emission$HorsesUp3yr          <- c(farm$Value[farm$Module=="Production::Other[HorsesUp3yr]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Other[HorsesUp3yr]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$HorsesUp3yr,
                                    totalApplication * excretionShare$HorsesUp3yr
                                   );
emission$Mules                <- c(farm$Value[farm$Module=="Production::Other[Mules]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Other[Mules]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Mules,
                                    totalApplication * excretionShare$Mules
                                   );
emission$Asses                <- c(farm$Value[farm$Module=="Production::Other[Asses]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Other[Asses]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Asses,
                                    totalApplication * excretionShare$Asses
                                   );
emission$Goats                <- c(farm$Value[farm$Module=="Production::Other[Goats]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Other[Goats]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Goats,
                                    totalApplication * excretionShare$Goats
                                   );
emission$Sheep                <- c(farm$Value[farm$Module=="Production::Other[Sheep]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Other[Sheep]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Sheep,
                                    totalApplication * excretionShare$Sheep
                                   );
emission$Milksheep            <- c(farm$Value[farm$Module=="Production::Other[Milksheep]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Other[Milksheep]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Milksheep,
                                    totalApplication * excretionShare$Milksheep
                                   );

emission$Layers               <- c(farm$Value[farm$Module=="Production::Poultry[Layers]::Outdoor" & farm$Variable=="nh3_noutdoor"],
                                    farm$Value[farm$Module=="Production::Poultry[Layers]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Layers,
                                    totalApplication * excretionShare$Layers
                                  );
emission$Growers              <- c(farm$Value[farm$Module=="Production::Poultry[Growers]::Outdoor" & farm$Variable=="nh3_noutdoor"],
                                    farm$Value[farm$Module=="Production::Poultry[Growers]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Growers,
                                    totalApplication * excretionShare$Growers
                                    );
emission$Broilers             <- c(farm$Value[farm$Module=="Production::Poultry[Broilers]::Outdoor" & farm$Variable=="nh3_noutdoor"],
                                    farm$Value[farm$Module=="Production::Poultry[Broilers]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Broilers,
                                    totalApplication * excretionShare$Broilers
                                    );
emission$Turkeys              <- c(farm$Value[farm$Module=="Production::Poultry[Turkeys]::Outdoor" & farm$Variable=="nh3_noutdoor"],
                                    farm$Value[farm$Module=="Production::Poultry[Turkeys]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$Turkeys,
                                    totalApplication * excretionShare$Turkeys
                                   );
emission$OtherPoultry         <- c(farm$Value[farm$Module=="Production::Poultry[OtherPoultry]::Outdoor" & farm$Variable=="nh3_noutdoor"],
                                    farm$Value[farm$Module=="Production::Poultry[OtherPoultry]::Housing" & farm$Variable=="nh3_nhousing"],
                                    0,
                                    totalStorage * excretionShare$OtherPoultry,
                                    totalApplication * excretionShare$OtherPoultry
                                   );
as.list(emission);


#barNamesEN = c("DairyCow", "Heifers1yr", "Heifers2yr", "Pig");
barplot(cbind(emission$DairyCow, emission$Heifers1yr, emission$Heifers2yr, emission$Heifers3yr, emission$Beefcattle, emission$Fatteningcalves, emission$PreBeefcalves, emission$SucklingCows, emission$DrySows, emission$NursingSows, emission$FatteningPigs, emission$Piglets, emission$Boars, emission$HorsesLw3yr, emission$HorsesUp3yr, emission$Mules, emission$Asses, emission$Goats, emission$Sheep, emission$Milksheep, emission$Layers, emission$Growers, emission$Broilers, emission$Turkeys, emission$OtherPoultry),
        names.arg=AnimalCategories,
        ylab="kg N /yr",
        las=2,
        col=colors,main="NH3 emission per animal category");

#if(plotPdf){
#  dev.off();
#}else{
#}
