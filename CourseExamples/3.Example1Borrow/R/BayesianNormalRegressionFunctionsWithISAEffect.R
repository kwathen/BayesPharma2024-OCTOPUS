
SamplePosteriorWithISAEffect<- function( lData, cAnalysis, nQtySamplesPerChain , dDelta )
{
    lInits           <- list( InitsNormalModelWithISAEffect( cAnalysis ), InitsNormalModelWithISAEffect( cAnalysis ), 
                              InitsNormalModelWithISAEffect( cAnalysis ))  # Going to run 3 chains
    #strModelFile     <- paste0( "BayesianModel1.txt" )
    #model            <- jags.model( textConnection( strModel ), lData, lInits, n.chains=3, quiet = TRUE  )
    
    # Option 2 - Add model string directly in this code
    strModel <- "model
                {
                    # N observations
                    for( i in 1:nQtyPats )
                    {

                        vY[i] ~ dnorm( vMean[ i ], dTau )
                        vMean[ i ] 	<- dBeta0 + vTreatment[ i ]*dBeta1  + vExternalControl[ i ]*dBeta2 
                    }


                    # Priors
                    dBeta0   ~ dnorm( dBeta0PriorMean, 1/( dBeta0PriorSD*dBeta0PriorSD ) )
                    dBeta1   ~ dnorm( dBeta1PriorMean, 1/( dBeta1PriorSD*dBeta1PriorSD )  )
                    dBeta2   ~ dnorm( dBeta2PriorMean, 1/( dBeta2PriorSD*dBeta2PriorSD )  )
                    dTau      ~ dgamma( 0.001, 0.001 )
                }"


    model            <- jags.model( textConnection( strModel ), lData, lInits, n.chains=3, quiet = TRUE  )


    update( model, 1000, progress.bar = "none", quiet = TRUE)
    vTrace          <- c("dBeta0", "dBeta1", "dBeta2", "dTau" )
    mSamps          <- coda.samples( model, vTrace , n.iter=nQtySamplesPerChain, quiet = TRUE, progress.bar = "none" )
    mSamps          <- rbind(mSamps[,][[1]],mSamps[,][[2]],mSamps[,][[3]])
    
    
    vBeta0          <- mSamps[ , 1 ]
    vBeta1          <- mSamps[ , 2 ]
    vBeta2          <- mSamps[ , 3 ]
    vTau            <- mSamps[ , 4 ]
    
    
    dPrGrtMAV       <- mean( ifelse( vBeta1 > dDelta, 1, 0) )
    
    
    return( list( dPrGrtMAV = dPrGrtMAV, vBeta0 = vBeta0, vBeta1 = vBeta1 ) )
    
}


InitsNormalModelWithISAEffect <- function( cAnalysis )
{
    
    dBeta0   <-  rnorm( 1, cAnalysis$dBeta0PriorMean, cAnalysis$dBeta0PriorSD )
    dBeta1   <-  rnorm( 1, cAnalysis$dBeta1PriorMean, cAnalysis$dBeta1PriorSD )
    dBeta2   <-  rnorm( 1, cAnalysis$dBeta2PriorMean, cAnalysis$dBeta2PriorSD )
    dTau     <-  runif( 1, 0.001, 10 ) 
    
    return( list( dBeta0 = dBeta0, dBeta1 = dBeta1, dBeta2 = dBeta2, dTau = dTau ) )
}
