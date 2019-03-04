createDatabaseList <- function(){
  #Generate DB Object
  ccae = list (
    schema = "CDM_TRUVEN_CCAE_V697.dbo",
    db.name = "CCAE",
    dbID = 1000000000
  )

  mdcr = list (
    schema = "CDM_TRUVEN_MDCR_V698.dbo",
    db.name = "MDCR",
    dbID = 2000000000
  )

  mdcd = list (
    schema = "CDM_TRUVEN_MDCD_V699.dbo",
    db.name = "MDCD",
    dbID = 3000000000
  )

  optum_ses = list (
    schema = "CDM_OPTUM_EXTENDED_SES_V694.dbo",
    db.name = "OPTUM_SES",
    dbID = 4000000000

  )

  datasources <- list(ccae,mdcr,mdcd,optum_ses)
  rm(ccae,mdcr,mdcd,optum_ses)
  return(datasources)
}
