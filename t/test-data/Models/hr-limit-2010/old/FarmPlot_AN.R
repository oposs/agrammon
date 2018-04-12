#
#  Skript to graphicaly Plot results from Agrammon
#
#
#  BjE, 9. July 2008
#
##############

# Global Parameters
resultFile <- "result_dairycow_Basis.txt";                # result File as Input for displaying Graphics

# read Inputfile
farm <- read.table(resultFile, sep="|", skip=0, strip.white=TRUE, header=TRUE);

#plotPdf <- 1

if(plotPdf){
#  pdf("result.pdf",width=11.75,height=8.25);
   pdf("result_2000.pdf",width=8.25,height=11.75);
   par(omi=0.39737007878*c(1,2.5,1,1));
   par(pty="s")

}else{
}

mtext("Results Agrammon");

colGrazing <- "#33CCCC";
colYard <- "#FFFF99";
colHousing <- "#FFFF00";
colStorage <- "#FF0000";
colApplication <- "#660066";
colRemainApplication <- "#008000";
colRemainPasture <- "#00FF00";

colors <- c(colGrazing, colYard, colHousing, colStorage, colApplication, colRemainApplication, colRemainPasture );

layout(matrix(c(1,2,3,4,4,4,5,5,6),3,3,byrow=TRUE));

# Global Variables
totalStorage            <- farm$Value[farm$Module=="Storage" & farm$Variable=="nh3_nstorage"];
totalApplication        <- farm$Value[farm$Module=="Application" & farm$Variable=="nh3_napplication"];
totalExcretion          <- farm$Value[farm$Module=="Production" & farm$Variable=="n_excretion"];
totalEmissionProduction <- (farm$Value[farm$Module=="Production" & farm$Variable=="nh3_nproduction"]+
                            farm$Value[farm$Modul=="Production" & farm$Variable=="nh3_nhousing"]+
                            farm$Value[farm$Modul=="Production" & farm$Variable=="nh3_nyard"]+
                            farm$Value[farm$Modul=="Production" & farm$Variable=="nh3_ngrazing"]+
                            farm$Value[farm$Module=="Production" & farm$Variable=="n_remain_pasture"]
                            );
totalEmission           <- (totalEmissionProduction + totalStorage + totalApplication);
AnimalCategories        <- c("DairyCow",          #Dairy Cows
                             "Heifers1yr", "Heifers2yr", "Heifers3y", "Beefcattle", "Beefcalves", "PreBeefcalves", "SucklingCows", # Cattle
                              "DrySows", "NursingSows", "FatteningPigs", "Piglets", "Boars", # Pig
                             "HorsesLw3yr", "HorsesUp3yr", "Mules", "Asses", "Goats", "Sheep", "Milksheep", # Other
                             "Layers", "Growers", "Broilers", "Turkeys", "OtherPoultry" # Poultry
                             );


## Pi Chart with shares of Excretion per Animal Category
excretionShare <-  list();
excretionShare$DairyCow       <- farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Heifers1yr     <- farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Heifers2yr     <- farm$Value[farm$Module=="Production::Cattle[Heifers2yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Heifers3yr     <- farm$Value[farm$Module=="Production::Cattle[Heifers3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Beefcattle     <- farm$Value[farm$Module=="Production::Cattle[Beefcattle]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Beefcalves     <- farm$Value[farm$Module=="Production::Cattle[Beefcalves]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$PreBeefcalves  <- farm$Value[farm$Module=="Production::Cattle[PreBeefcalves]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$SucklingCows   <- farm$Value[farm$Module=="Production::Cattle[SucklingCows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;

excretionShare$DrySows        <- farm$Value[farm$Module=="Production::Pig[DrySows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$NursingSows    <- farm$Value[farm$Module=="Production::Pig[NursingSows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$FatteningPigs  <- farm$Value[farm$Module=="Production::Pig[FatteningPigs]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Piglets        <- farm$Value[farm$Module=="Production::Pig[Piglets]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Boars          <- farm$Value[farm$Module=="Production::Pig[Boars]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;

excretionShare$HorsesLw3yr    <- farm$Value[farm$Module=="Production::Other[HorsesLw3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$HorsesUp3yr    <- farm$Value[farm$Module=="Production::Other[HorsesUp3yr]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Mules          <- farm$Value[farm$Module=="Production::Other[Mules]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Asses          <- farm$Value[farm$Module=="Production::Other[Asses]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Goats          <- farm$Value[farm$Module=="Production::Other[Goats]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Sheep          <- farm$Value[farm$Module=="Production::Other[Sheep]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Milksheep      <- farm$Value[farm$Module=="Production::Other[Milksheep]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;

excretionShare$Layers         <- farm$Value[farm$Module=="Production::Poultry[Layers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Growers        <- farm$Value[farm$Module=="Production::Poultry[Growers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Broilers       <- farm$Value[farm$Module=="Production::Poultry[Broilers]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$Turkeys        <- farm$Value[farm$Module=="Production::Poultry[Turkeys]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$OtherPoultry   <- farm$Value[farm$Module=="Production::Poultry[OtherPoultry]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
as.list(excretionShare);

pie(x=unlist(excretionShare), main = "Share of Excretion" );  
#pie(c(1), main = "Share of Excretion" );  


## Pi Chart with shares of Emissions per Animal Category
emissionShare <-  list();
emissionShare$Production      <- (totalEmissionProduction /  totalEmission);
emissionShare$Storage         <- (totalStorage / totalEmission);
emissionShare$Application     <- (totalApplication /  totalEmission);
as.list(emissionShare);

pie(x=unlist(emissionShare), main = "Share of Emission" );


## Bar Plot Total Emissions
total <- c( farm$Value[farm$Module=="Production" & farm$Variable=="nh3_ngrazing"],
            farm$Value[farm$Module=="Production" & farm$Variable=="nh3_nyard"],
            farm$Value[farm$Module=="Production" & farm$Variable=="nh3_nhousing"],
            farm$Value[farm$Module=="Storage" & farm$Variable=="nh3_nstorage"],
            farm$Value[farm$Module=="Application" & farm$Variable=="nh3_napplication"],
            farm$Value[farm$Module=="Application" & farm$Variable=="n_out_application"],
            farm$Value[farm$Module=="Production" & farm$Variable=="n_remain_pasture"]
          );

barplot(cbind(total),
        names.arg=c("Total Farm"),
        ylim=c(0,sum(total,na.rm=TRUE)*1.1),
        xlim=c(0,2),
        ylab="kg N /yr",
        legend,
        col=colors,main="Emission & Appl.");


## Bar Plot Animal Categories
emission <-  list();
emission$DairyCow             <- c( farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::DairyCow[DairyCow]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$DairyCow,
                                    totalApplication * excretionShare$DairyCow
                                  );
emission$Heifers1yr            <- c( farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Heifers1yr]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$Heifers1yr,
                                    totalApplication * excretionShare$Heifers1yr
                                  );
emission$Heifers2yr            <- c( farm$Value[farm$Module=="Production::Cattle[Heifers2yr]::Grazing" & farm$Variable=="nh3_ngrazing"],
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
emission$Beefcalves           <- c(farm$Value[farm$Module=="Production::Cattle[Beefcalves]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Beefcalves]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Beefcalves]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$Beefcalves,
                                    totalApplication * excretionShare$Beefcalves
                                   );
emission$PreBeefcalves          <- c(farm$Value[farm$Module=="Production::Cattle[PreBeefcalves]::Grazing" & farm$Variable=="nh3_ngrazing"],
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
                                    farm$Value[farm$Module=="Production::Poultry[Layers]::Yard" & farm$Variable=="nh3_nyard"],
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
barplot(cbind(emission$DairyCow, emission$Heifers1yr, emission$Heifers2yr, emission$Heifers3yr, emission$Beefcattle, emission$Beefcalves, emission$PreBeefcalves, emission$SucklingCows, emission$DrySows, emission$NursingSows, emission$FatteningPigs, emission$Piglets, emission$Boars, emission$HorsesLw3yr, emission$HorsesUp3yr, emission$Mules, emission$Asses, emission$Goats, emission$Sheep, emission$Milksheep, emission$Layers, emission$Growers, emission$Broilers, emission$Turkeys, emission$OtherPoultry),
        names.arg=AnimalCategories,
        ylab="kg N /yr",
        las=2,
        col=colors,main="Emission");

plot(1); # Place Holder 
plot(1); # Place Holder

if(plotPdf){
  dev.off();
}else{
}
