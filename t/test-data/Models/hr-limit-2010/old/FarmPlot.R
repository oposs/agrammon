#
#  Skript to graphicaly Plot results from Agrammon
#
#
#  BjE, 9. June 2008
#
##############

# Global Parameters
resultFile <- "result.txt";                # result File as Input for displaying Graphics

# read Inputfile
farm<- read.table(resultFile, sep="|", skip=0, strip.white=TRUE, header=TRUE);

if(plotPdf){
  pdf("result.pdf",width=11.75,height=8.25);
  par(omi=0.39737007878*c(1,2.5,1,1));
  par(pty="s")

}else{
}


mtext("Resultate Agrammon");

colGrazing <- "#33CCCC";
colYard <- "#FFFF99";
colHousing <- "#FFFF00";
colStorage <- "#FF0000";
colApplication <- "#660066";
colRemainApplication <- "#008000";
colRemainPasture <- "#00FF00";

colors <- c(colGrazing, colYard, colHousing, colStorage, colApplication, colRemainApplication, colRemainPasture );

layout(matrix(c(1,2,3,4,4,5,6, 6,7),3,3,byrow=TRUE));

## Pi Chart with shares of Excretion per Animal Categorie
animalCategories <- c("dairyCow",          #Dairy Cows
                      "heifers1yr", "heifers2yr", "heifers3y", "beefcattle", "beefcalves", "sucklingcows", # Cattle
                      "nursing_sows", "dry_sows", "piglets", "fattening_pigs", "boars", # Pig
                      "horses_lw3yr", "horses_3yr_up", "mules", "asses", "goats", "sheep", "milksheep", # Other
                      "layers", "growers", "broilers", "turkeys", "other_poultry" # Poultry
                      ); 
totalStorage <- farm$Value[farm$Module=="Storage" & farm$Variable=="nh3_nstorage"];
totalApplication <- farm$Value[farm$Module=="Application" & farm$Variable=="nh3_napplication"];
totalExcretion <- farm$Value[farm$Module=="Production" & farm$Variable=="n_excretion"];

excretionShare <-  list();
excretionShare$dairyCow       <- farm$Value[farm$Module=="Production::DairyCow[Stable 1]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$heifers1yr     <- farm$Value[farm$Module=="Production::Cattle[Stable 1]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$heifers2yr     <- farm$Value[farm$Module=="Production::Cattle[Stable 2]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$heifers3yr     <- farm$Value[farm$Module=="Production::Cattle[Stable 3]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$beefcattle     <- farm$Value[farm$Module=="Production::Cattle[Stable 3]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$beefcalves     <- farm$Value[farm$Module=="Production::Cattle[beefcalves]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$sucklingcows   <- farm$Value[farm$Module=="Production::Cattle[sucklingcows]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$nursingSows    <- 0;
excretionShare$drySows        <- 0;
excretionShare$piglets        <- 0;
excretionShare$fatteningPigs  <- farm$Value[farm$Module=="Production::Pig[Stable 1]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$boars          <- 0;
excretionShare$horseslw3yr    <- 0;
excretionShare$horses3yrUp    <- 0;
excretionShare$mules          <- 0;
excretionShare$asses          <- 0;
excretionShare$goats          <- 0;
excretionShare$sheep          <- 0;
excretionShare$milksheep      <- 0;
excretionShare$layers         <- farm$Value[farm$Module=="Production::Poultry[Stable 1]::Excretion" & farm$Variable=="n_excretion"] /  totalExcretion;
excretionShare$growers        <- 0;
excretionShare$broilers       <- 0;
excretionShare$turkeys        <- 0;
excretionShare$otherPoultry   <- 0;
as.list(excretionShare);

pie(x=unlist(excretionShare), main = "Share of Excretion" );  

## Pi Chart with shares of Emissions per Animal Categorie

pie(c(1), main = "Share of Emission"); # Place Holder 

## Bar Plot Total Emissions


totalStorage <- farm$Value[farm$Module=="Storage" & farm$Variable=="nh3_nstorage"];
totalApplication <- farm$Value[farm$Module=="Application" & farm$Variable=="nh3_napplication"];

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
        col=colors,main="Emission & Appl.");


## Bar Plot Animal Categories
emission <-  list();
emission$dairyCow             <- c( farm$Value[farm$Module=="Production::DairyCow[Stable 1]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::DairyCow[Stable 1]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::DairyCow[Stable 1]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$DairyCow,
                                    totalApplication * excretionShare$DairyCow
                                  );


emission$heifers1yr            <- c( farm$Value[farm$Module=="Production::Cattle[Stable 2]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Stable 2]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Stable 2]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$cattle1yr,
                                    totalApplication * excretionShare$cattle1yr
                                  );

emission$heifers2yr            <- c( farm$Value[farm$Module=="Production::Cattle[Stable 3]::Grazing" & farm$Variable=="nh3_ngrazing"],
                                    farm$Value[farm$Module=="Production::Cattle[Stable 3]::Housing" & farm$Variable=="nh3_nhousing"],
                                    farm$Value[farm$Module=="Production::Cattle[Stable 3]::Yard" & farm$Variable=="nh3_nyard"],
                                    totalStorage * excretionShare$cattle2yr,
                                    totalApplication * excretionShare$cattle2yr
                                  );

emission$heifers3yr           <- c( 0, 0, 0, 0, 0);
emission$beefcattle           <- c( 0, 0, 0, 0, 0);
emission$beefcalves           <- c( 0, 0, 0, 0, 0);
emission$sucklingcows         <- c( 0, 0, 0, 0, 0);
emission$nursingSows          <- c( 0, 0, 0, 0, 0);
emission$drySows              <- c( 0, 0, 0, 0, 0);
emission$piglets              <- c( 0, 0, 0, 0, 0);
emission$fatteningPigs        <- c( 0, 0, 0, 0, 0);
emission$boars                <- c( 0, 0, 0, 0, 0);
emission$horseslw3yr          <- c( 0, 0, 0, 0, 0);
emission$horses3yrUp          <- c( 0, 0, 0, 0, 0);
emission$mules                <- c( 0, 0, 0, 0, 0);
emission$asses                <- c( 0, 0, 0, 0, 0);
emission$goats                <- c( 0, 0, 0, 0, 0);
emission$sheep                <- c( 0, 0, 0, 0, 0);
emission$milksheep            <- c( 0, 0, 0, 0, 0);
emission$layers               <- c( 0, 0, 0, 0, 0);
emission$growers              <- c( 0, 0, 0, 0, 0);
emission$broilers             <- c( 0, 0, 0, 0, 0);
emission$turkeys              <- c( 0, 0, 0, 0, 0);
emission$otherPoultry         <- c( 0, 0, 0, 0, 0);
as.list(emission);


barNamesEN = c("Dairy Cow", "Cattle 1 yr", "Cattle 2yr", "Pigs");
barplot( cbind(emission$dairyCow, emission$heifers1yr, emission$heifers2yr, emission$heifers3yr, emission$beefcattle, emission$beefcalves, emission$sucklingcows, emission$nursingSows, emission$drySows, emission$piglets, emission$fatteningPigs, emission$boars, emission$horseslw3yr, emission$horses3yrUp, emission$mules, emission$asses, emission$goats, emission$sheep, emission$milksheep, emission$layers,emission$growers, emission$broilers, emission$turkeys, emission$otherPoultry ),
        names.arg=animalCategories,
        ylab="kg N /yr",
        col=colors,main="Emission");


plot(1); # Place Holder for legend



plot(1); # Place Holder 
plot(1); # Place Holder 
