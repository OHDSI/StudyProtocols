getConnectionDetails <- function(configFile){
  config <- read.csv(configFile,as.is=TRUE)[1,]

  Sys.setenv(dbms = config$dbms)
  Sys.setenv(user = config$user)
  Sys.setenv(pw = config$pw)
  Sys.setenv(server = config$server)
  Sys.setenv(port = config$port)
  Sys.setenv(writeTo = config$writeTo)
  Sys.setenv(vocabulary = config$vocabulary)
  rm(config)

  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("dbms"),
    server = Sys.getenv("server"),
    port = as.numeric(Sys.getenv("port"))
    #user = Sys.getenv("user"),
    #password = Sys.getenv("pw")
  )

  return(connectionDetails)
}
