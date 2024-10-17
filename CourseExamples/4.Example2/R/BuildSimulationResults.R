# This file will process the simulation results and create several .RData files containing ISA results and the trial results


library( OCTOPUS )
source( "R/PostProcess.R")

dfResults <- BuildSimulationResultsDataSet( )

lResults <- ProcessSimulationResults( )
dfResSub <- lResults$mResults   #[ lResults$mResults$scenario <=7, ]
PlotResults( dfResSub)  #Plots with Go, No Go, Pause but no IA specific info

PlotResultsWithIAInfo( dfResSub ) #Plots with Go, No Go, Pause but no IA specific info


source( "R/PlatformTrialPlots.R")
library( lubridate)

# If you don't supply and end date then the graph focuses on one design but comparing designs can be difficult
# because the scale may not be the same 
dStart         <- ymd( "2025/01/01")
vUniqueDesigns <- unique( dfResSub$design )

TimeLinePlot(dfResSub, dStart, vDesigns = vUniqueDesigns[2], nScenario = 2 )
TimeLinePlot(dfResSub, dStart, vDesigns = vUniqueDesigns[4], nScenario = 2 )



# When comparing, having the end date can make the comparison much more meaningful 
dStart         <- ymd( "2025/01/01")
dEnd           <- ymd( "2027/06/01")
vUniqueDesigns <- unique( dfResSub$design )

TimeLinePlot(dfResSub, dStart,dEnd, vDesigns = vUniqueDesigns[2], nScenario = 2 )
TimeLinePlot(dfResSub, dStart,dEnd, vDesigns = vUniqueDesigns[4], nScenario = 2 )

