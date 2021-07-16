N <- 10000
addressesFile <- 'blue-mountains-lithgow-addresses-epsg7855.csv'
archetypesAttributesFile <- "archetypes-attributes.csv"
outfile <- 'population.csv'

# distribution of archetypes as per Strahan et al.’s data 
pArchetypes <-c(
  "Considered.Evacuator"     = 0.130, 
  "Community.Guided"         = 0.119, 
  "Threat.Denier"            = 0.065, 
  "Worried.Waverer"          = 0.171, 
  "Responsibility.Denier"    = 0.094,
  "Dependent.Evacuators"     = 0.098,
  "Experienced.Independent"  = 0.229, 
  "Unknown.Type"             = 0.093
)



popn <- data.frame(
  # archetype
  Archetype = character(N),
  # java class for modelled behaviour
  BDIAgentType = character(N),
  # daily activities locations
  homeX = double(N),
  homeY = double(N),
  # evacuation related locations
  EvacLocationPreference = character(N),
  InvacLocationPreference = character(N),
  # for those with dependants
  HasDependents.Logical = character(N),
  HasDependentsAtLocation = character(N),
  WillGoHomeAfterVisitingDependents.Logical = character(N),
  # for those without dependants
  WillGoHomeBeforeLeaving.Logical = character(N),
  # those determined to stay
  WillStay.Logical = character(N),
  # response thresholds
  ResponseThresholdInitial.Numeric = double(N),
  ResponseThresholdFinal.Numeric = double(N),
  # deliberation times
  LagTimeInMinsForFinalResponse.Numeric = double(N),
  LagTimeInMinsForInitialResponse.Numeric = double(N),
  # impact values
  ImpactFromFireDangerIndexRating.Literal = double(N),
  ImpactFromImmersionInSmoke.Literal = double(N),
  ImpactFromMessageAdvice.Literal = double(N),
  ImpactFromMessageEmergencyWarning.Literal = double(N),
  ImpactFromMessageEvacuateNow.Literal = double(N),
  ImpactFromMessageRespondersAttending.Literal = double(N),
  ImpactFromMessageWatchAndAct.Literal = double(N),
  ImpactFromSocialMessage.Literal = double(N),
  ImpactFromVisibleEmbers.Literal = double(N),
  ImpactFromVisibleFire.Literal = double(N),
  ImpactFromVisibleResponders.Literal = double(N),
  ImpactFromVisibleSmoke.Literal = double(N)
)


assign_archetypes_attributes <- function(probsfile, population) {
  # Assign the attributes based on the read probabilities
  # Here attribute names have special meaning:
  # <name>.Logical is treated as the probability of a TRUE value
  # <name>.Numeric is treated as the mean, with an assumed sigma=0.1
  # All assinged values are clipped to the interval (0.0,1.0).
  # The '.Logical' and '.Numeric' prefix are removed before writing out.
  
  # Read the probabilities to assign
  probs_orig<-read.csv(probsfile,header = T, sep=',', stringsAsFactors=F, strip.white = T, row.names=1)
  archetypes<-colnames(probs_orig)
  attributes<-rownames(probs_orig)
  filterLogical<-grepl(".Logical",attributes)
  filterNumeric<-grepl(".Numeric",attributes)
  filterLiteral<-grepl(".Literal",attributes)
  
  # Read the archetypes population
  orig<-population
  
  df<-orig
  df[,attributes]<-0
  
  for (archetype in archetypes) {
    filter<-orig$Archetype==archetype 
    len<-sum(filter)
    probs<-probs_orig[attributes,archetype]
    vals<-matrix(rep(0,len*length(attributes)), ncol=length(attributes), nrow=len); colnames(vals)<-attributes
    
    # assign all logical attributes
    lvals<-t(matrix(rep(probs[filterLogical],len), nrow=sum(filterLogical), ncol=len))
    lvals<-apply(lvals,2,function(x) {rbinom(length(x),1,x[1])})
    vals[,filterLogical]<-lvals
    
    # assign all numerical attributes
    nvals<-t(matrix(rep(probs[filterNumeric],len), nrow=sum(filterNumeric), ncol=len))
    nvals<-apply(nvals,2,function(x) {rnorm(length(x),mean=x,sd=ifelse(x<1,0.1,x*0.2))})
    nvals<-round(nvals,digits=2)
    vals[,filterNumeric]<-nvals
    
    # assign all literal attributes
    cvals<-t(matrix(rep(probs[filterLiteral],len), nrow=sum(filterLiteral), ncol=len))
    cvals<-apply(cvals,2,function(x) {x})
    vals[,filterLiteral]<-cvals
    
    # replace the archetype cell values with the calculated ones
    df[filter,attributes]<-vals
  }
  
  #remove the .Logical and .Numeric prefix from the colnames
  cnames<-colnames(df)
  cnames<-gsub(".Logical","",cnames)
  cnames<-gsub(".Numeric","",cnames)
  cnames<-gsub(".Literal","",cnames)
  colnames(df)<-cnames
  
  # write it out
  return(df)
}

popn$Archetype <- sample(names(pArchetypes), N, replace=TRUE, prob=pArchetypes)
popn$BDIAgentType <- rep("io.github.agentsoz.ees.agents.archetype.ArchetypeAgent",N)

csv <- read.csv(addressesFile)
idx <- sample(nrow(csv), N, replace = (N > nrow(csv)))
df <- csv[idx,]
popn$homeX <- df$X
popn$homeY <- df$Y

popn$EvacLocationPreference <- "Cranebrook,845070,6263955"
popn$InvacLocationPreference <- "Cranebrook,845070,6263955"

popn <- assign_archetypes_attributes(archetypesAttributesFile, popn)

# assign dependants a random location in some radius
distances <- as.matrix(dist(data.frame(popn$homeX,(popn$homeY), diag=T, upper=T)))
popn$HasDependentsAtLocation <- unlist(sapply(1:nrow(popn), function(x) {
   if(popn[x,]$HasDependents==1) {
    f <- sample(which(distances[x,]>0 & distances[x,]<5000), 1)
    paste0(popn[f,]$homeX,",",popn[f,]$homeY)
   } else {
    ""
  }
}))

write.csv(popn, outfile, row.names=FALSE, quote=TRUE)
