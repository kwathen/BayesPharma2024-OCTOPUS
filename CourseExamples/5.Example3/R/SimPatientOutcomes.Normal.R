
################################################################################################### #
#   Description - This file will add a new patient outcome where patient outcomes are binary
#
#
#   THIS IS MOST LIKELY NOT THE PATIENT SIMULATION NEEDED SO THE USER WILL NEED TO UPDATE PER THEIR SIMULATION PLAN
################################################################################################### #

SimPatientOutcomes.Normal <- function(  cSimOutcomes, cISADesign, dfPatCovISA )
{
    #print( "Executing SimPatientOutcomes.Normal ...")
    if( !is.null(  dfPatCovISA  ) )
        stop( "SimPatientOutcomes.Normal is not designed to incorporate patient covariates and  dfPatCovISA  is not NULL.")
    
    
    mOutcome        <- NULL
    
    vMean           <- c( cSimOutcomes$MeanCtrl, cSimOutcomes$MeanExp )
    vStdDev         <- c( cSimOutcomes$StdCtrl, cSimOutcomes$StdExp )
    vQtyPats        <- cISADesign$vQtyPats
    
    vPatTrt         <- rep( cISADesign$vTrtLab, vQtyPats )
    iArm            <- 1
    for( iArm in 1:length( vQtyPats ) )
    {
        
        vPatientOutcomes <- rnorm( vQtyPats[ iArm ], mean = vMean[ iArm ], sd = vStdDev[ iArm ])        
        mOutcome         <- rbind( mOutcome, matrix( vPatientOutcomes , ncol = 1) )
    }
    
    
    lSimDataRet <- structure( list( mSimOut1 = mOutcome, vObsTime1 = cISADesign$cISAAnalysis$vAnalysis[[1]]$vObsTime ), class= class(cSimOutcomes) )
    
    
    lSimDataRet$nQtyOut  <- 1#length( cSimOutcomes )
    lSimDataRet$vPatTrt  <- vPatTrt
    
    return( lSimDataRet )
    
}

