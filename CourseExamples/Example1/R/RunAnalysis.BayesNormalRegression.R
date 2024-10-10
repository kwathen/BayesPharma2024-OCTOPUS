##### File Description ######################################################################################################
#   This file is to create the new RunAanlysis that calculates based on a beta-binomial
#   Inputs:
#     cAnalysis - The class( cAnalysis ) determines the specific version of RunAnalysis that is called. It contains
#                 the details about the analysis such as the priors, MAV, TV, decision cut-off boundaries.
#     lDataAna  - The data that is used int he analysis.  Typically contains vISA (the ISA for the patient),
#                 vTrt (treatment for each patient), vOut (the outcome for each patient)
#     nISAAnalysisIndx - index of the analysis used for changing boundaries)
#     bIsFinaISAAnalysis - TRUE or FALSE, often we change the value of the cut-off at the final analysis for an ISA
#     cRandomizer - The randomizer, mainly used for cases with covariates
#
#############################################################################################################################.
RunAnalysis.BayesNormalRegression <- function( cAnalysis, lDataAna,  nISAAnalysisIndx, bIsFinalISAAnalysis, cRandomizer )
{
    #Sprint( paste( "RunAnalysis.BayesNormalRegression"))
    
    vISA <- lDataAna$vISA
    vTrt <- lDataAna$vTrt
    vOut <- lDataAna$vOut
    
    # Using the is.na because it could be that a patient has not had the outcome observed at the time of the analysis
    vTrt <- vTrt[ !is.na( vOut ) ]
    vOut <- vOut[ !is.na( vOut ) ]
    
    # Need vTrt to be an indicator of the Experimental treatment 
    vTrt <- ifelse( vTrt ==1, 0, 1 )
    # Setup the list that is sent to sample the posterior, including data and prior info from the cAnalysis
    lData <- list( nQtyPats = length( vTrt ), 
                   vY = vOut,
                   vTreatment = vTrt,
                   dBeta0PriorMean =  cAnalysis$dBeta0PriorMean, 
                   dBeta0PriorSD   =  cAnalysis$dBeta0PriorSD,
                   dBeta1PriorMean =  cAnalysis$dBeta1PriorMean, 
                   dBeta1PriorSD   =  cAnalysis$dBeta1PriorSD  )
    
    
    
    # Note: These values could be added to the input if you are trying to determine them, often easy to hard code in this file
    nQtySamplesPerChain <- 2500
    dDelta              <- cAnalysis$dMAV
    
    lCals      <- SamplePosterior( lData, cAnalysis, nQtySamplesPerChain , dDelta )
    
    lCutoff    <- GetBayesianCutoffs( cAnalysis, nISAAnalysisIndx, bIsFinalISAAnalysis )
    
    lCalcs     <- list( dPrGrtMAV      = lCals$dPrGrtMAV,
                        dPUpperCutoff  = lCutoff$dPUpperCutoff,
                        dPLowerCutoff  = lCutoff$dPLowerCutoff )
    
    lRet       <- MakeDecisionBasedOnPostProb(cAnalysis, lCalcs )
    
    lRet$cRandomizer <- cRandomizer  # Needed because the main code will pull the randomizer off just in-case this function were to close a covariate group
    return( lRet )
    
    
}







