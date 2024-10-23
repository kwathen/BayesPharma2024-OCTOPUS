# This file will process the simulation results and create several .RData files containing ISA results and the trial results

library( ggplot2 )
library( OCTOPUS )
source( "R/PostProcess.R")

dfResults <- BuildSimulationResultsDataSet( )

lResults <- ProcessSimulationResults( )
dfResSub <- lResults$mResults   #[ lResults$mResults$scenario <=7, ]
PlotResults( dfResSub)  #Plots with Go, No Go, Pause but no IA specific info

PlotResultsWithIAInfo( dfResSub ) #Plots with Go, No Go, Pause but no IA specific info


source( "R/PlatformTrialPlots.R")
library( lubridate)


# When comparing, having the end date can make the comparison much more meaningful 
dStart         <- ymd( "2025/01/01")
dEnd           <- ymd( "2027/06/01")
vUniqueDesigns <- unique( dfResSub$design )


TimeLinePlot(dfResSub, dStart,dEnd, vDesigns = vUniqueDesigns[5], strTitle = "Design 5, Scenario 3", nScenario = 3 )
TimeLinePlot(dfResSub, dStart,dEnd, vDesigns = vUniqueDesigns[5], strTitle = "Design 5, Scenario 4", nScenario = 4 )

