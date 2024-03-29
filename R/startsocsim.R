#library("future")
#library(rsocsim)


#' Run a single socsim-simulation with a given supplement-file and folder.
#' The results will be saved into that folder
#'
#' @param rootfolder rootfolder...
#' @param folder base-directory of the simulation. 
#' @param supfile the .sup file to start the simulation, relative to the
#' folder
#' @param seed RNG seed as string, Default="42"
#' @param process_method specify whether and how SOCSIM should be started in its
#' own process or in the running R process. Use one of
#'  "inprocess" - SOCSIM runs in the R-process. Beware if you run several different
#'  simulations - they may affect later simulations
#'  "future" - the safest option. A new process will be start via the "future"
#'  package
#'  "clustercall" - if the future package is not available, try this method instead
#' @return The results will be written into the specified folder
#' @export
run1simulationwithfile <- function(folder, supfile,seed="42",process_method="inprocess",compatibility_mode="1") {
  seed= as.character(seed)
  compatibility_mode = as.character(compatibility_mode)
  print("Start run1simulationwithfile")
  print(folder)
  print(seed)
  previous_wd = getwd()
  result = NULL
  tryCatch(expr = {
    setwd(folder)
    if ((process_method=="inprocess") | (process_method =="default")) {
      result = run1simulationwithfile_inprocess(supfile=supfile,seed=seed,compatibility_mode=compatibility_mode)
    } else if (process_method=="future") {
      result = run1simulationwithfile_future(supfile=supfile,seed=seed,compatibility_mode=compatibility_mode)
    } else if (process_method=="clustercall") {
      result = run1simulationwithfile_clustercall(supfile=supfile,seed=seed,compatibility_mode=compatibility_mode)
    }
  },
  error = function(w){
    print("Error during execution of simulation!")
  },
  finally = {
    print(paste0("restore previous working dir: ", previous_wd))
    setwd(previous_wd)
  }
  )
  return(result)
  
}

run1simulationwithfile_future <- function(supfile,seed="42",compatibility_mode="1") {
  # use the "future" library to run a rcpp-socsim simulation
  # in a seperate process
  print("create future cluster")
  future::plan(future::multisession)
  print("after future::plan(future::multisession)")
  print("start socsim simulation now. no output will be shown!")
  
  f1 <- future::future({
    startSocsimWithFile(supfile,seed,compatibility_mode)
  },seed=TRUE)
  v1 <- future::value(f1)
  return(1)
}


#' Run a socsim-simulation in the r-process
#'
#' @param rootfolder rootfolder  name of the simulation
#' @param supfile the .sup file to start the simulation
#' @param seed RNG seed
#' @return The results will be written into the specified folder

run1simulationwithfile_inprocess <- function(folder, supfile,seed,compatibility_mode="1") {
  startSocsimWithFile(supfile,seed,compatibility_mode)
  return(1)
}



# Deprecated for now!
#run1simulationwithfile_apply <- function(folder, supfile,seed="23") {
#  # use the "future" library to run a rcpp-socsim simulation
#  # in a seperate process
#  folder = "D:\\dev\\r\\socsimprojects\\CousinDiversity"
#  supfile = "CousinDiversity.sup"
#  seed = "23"
#  numCores=2
#  cl <- parallel::makeCluster(numCores, type="PSOCK", outfile="")
#  parallel::clusterExport(cl, run1simulationwithfile_inprocess)
#  parallel::parLapply(cl,c(2),run1simulationwithfile_inprocess, folder=folder, supfile=supfile,seed=seed)
#  # now there is a mysterious error: startSocsimWithFile is not available somehow????? 
#  parallel::stopCluster(cl)
#  return(1)
#}

run1simulationwithfile_clustercall <- function(supfile,seed="23",compatibility_mode="1") {
  # use the "future" library to run a rcpp-socsim simulation
  # in a seperate process
  print("parallel::clusterCall")
  numCores=1
  cl <- parallel::makeCluster(numCores, type="PSOCK", outfile="socsim_clustercall.log")
  parallel::clusterExport(cl, "startSocsimWithFile")
  parallel::clusterCall(cl,startSocsimWithFile, supfile=supfile,seed=seed,compatibility_mode=compatibility_mode)
  parallel::stopCluster(cl)
  return(1)
}

#bla <- function(){
#  print("function bla")
#    folder = "D:\\dev\\r\\socsimprojects\\CousinDiversity"
#  supfile = "CousinDiversity.sup"
#  seed="33"
#  previous_wd = getwd()
#  setwd(paste0(folder))
#  print(seed)
#  startSocsimWithFile(supfile,seed)
#  setwd(previous_wd)
#  return(1) 
#}

#' Run a single socsim-simulation with a socsim binary.
#' the place
#' The results will be saved into that folder
#'
#' @param rootfolder rootfolder...
#' @param folder base-directory of the simulation. 
#' @param supfile the .sup file to start the simulation, relative to the
#' folder
#' @param seed RNG seed as string, Default="42"
#' @param socsim_path path+filename of a socsim-executable. Download one from https://github.com/tomthe/socsim/releases/download/0.3/socsim.exe
#' @return The results will be written into the specified folder
#' @export
run1simulationwithfile_from_binary <- function(folder, supfile,seed="42",compatibility_mode="1",socsim_path=NULL) {
  if (is.null(socsim_path)){
    print("No socsim_path specified. So I will download the Windows-binary from github to a temporary directory!")
    print("This will probably not work due to antivirus-software.")
    print("please download an executable socsim from https://github.com/tomthe/socsim/releases/download/0.3/socsim.exe")
    print("then save the whole path and specify it as socsim_path for this function!")
    url = "https://github.com/tomthe/socsim/releases/download/0.3/socsim.exe"
    socsim_path = paste0(tempdir(),"\\","socsim.exe")
    download.file(url,socsim_path,method="auto")
  }
  seed = toString(seed)
  print("Start run1simulationwithfile")
  print(folder)
  print(supfile)
  print(paste0("socsim_path: ", socsim_path))
  print(seed)
  previous_wd = getwd()
  setwd(paste0(folder))
  
  print(paste0("command:  ",socsim_path,args=paste0(" ",supfile," ", seed," ", compatibility_mode)))
  
  print(system2(socsim_path,args=c(supfile," ", seed, " ",compatibility_mode)))
  print(system(paste(socsim_path, supfile, seed,compatibility_mode)))
  a = (system(paste(socsim_path, paste0(dirname(folder), "\\", supfile), seed, compatibility_mode)))
  print(paste(socsim_path, paste0(dirname(folder), "\\", supfile), seed,compatibility_mode))
  print(a)
  print(previous_wd)
  setwd(previous_wd)
  return(1)
}

#' create a folder in the user-dir of the current user in the socsim-subfolder
#' @param simulation_name optional name for the simulation
#' @param basefolder optional base directory where the folder will be created
#' @return the path to the folder
#' @export
create_simulation_folder <- function(simulation_name=NULL,basefolder=NULL) {
  if (is.null(simulation_name)) {
    # create a random name that starts with socsim_sim_
    simulation_name = paste0("socsim_sim_",as.character(sample(1:10000, 1)))
  }
  if (is.null(basefolder)) {
    # check whether there is a "socsim" folder in the users home-directory:
    # if not, create it
    userdir <- dirname(path.expand("~"))
    basefolder = paste0(userdir, "/", "socsim")
  }
  if (!file.exists(basefolder)) {
    dir.create(basefolder)
  }
  # create the subfolder
  subfolder <- paste0(basefolder, "/", simulation_name)
  if (!file.exists(subfolder)) {
    dir.create(subfolder)
  }
  return(subfolder)
}

#' create a basic .sup file for a simulation
#' the simulation is only a simple one
#' the file will be saved into the sim-folder
#' @param simfolder the folder where the sup-file will be saved
#' @param simname the name of the simulation
#' @return sup.fn the filename of the supplementary file
#' which is needed to start the simulation
#' @export
create_sup_file <- function(simfolder, simname) {
  sup.content <- "
*Supervisory file for a stable population
* 20220120
marriage_queues 1
bint 10
segments 1
marriage_eval distribution
input_file init_new
*
duration 1000
include SWEfert2022
include SWEmort2022
run
"
  sup.fn <- "socsim.sup"
  cat(sup.content,file=file.path(simfolder, sup.fn))
  fn_SWEfert2022_source <- system.file("extdata", "SWEfert2022", package = "rsocsim", mustWork = TRUE)
  fn_SWEfert2022_dest <- file.path(simfolder, "SWEfert2022")
  fn_SWEmort2022_source <- system.file("extdata", "SWEmort2022", package = "rsocsim", mustWork = TRUE)
  fn_SWEmort2022_dest <- file.path(simfolder, "SWEmort2022")
  fn_init_source <- system.file("extdata", "init_new.opop", package = "rsocsim", mustWork = TRUE)
  fn_init_dest <- file.path(simfolder, "init_new.opop")
  file.copy(fn_SWEfert2022_source,fn_SWEfert2022_dest)
  file.copy(fn_SWEmort2022_source,fn_SWEmort2022_dest)
  file.copy(fn_init_source,fn_init_dest)
  return(sup.fn)
}

#' read the content of the supplement file 
#' @param simfolder base folder of the simulation
#' @param simname name of the .sup-file
#' @return the content of the supplement file as a string (TODO: Now it 
#' returns a list of lines instead of a single string)
#' @export
get_supplement_content <- function(simfolder, sup_fn) {
  if (is.null(sup_fn)) {
    sup_fn <- "socsim.sup"
  }
  sup_content <- readLines(file.path(simfolder, sup_fn))
  return(sup_content)
}



#' simulation_time_to_years
#' convert the time measures.
#' @param simulation time
#' @param pre-simulation-time - how long the simulation ran to get a stable population
#' @param start-year - the year the simulation started
#' @return year, a number like 2022.2
#' @export
simulation_time_to_years <- function(simulation_time, pre_simulation_time, start_year) {
  return(start_year + (simulation_time - pre_simulation_time)/12)
}
