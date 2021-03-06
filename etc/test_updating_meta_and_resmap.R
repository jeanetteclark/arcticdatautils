#' Test updating an existing metadata object that is part of a data package.
#'
#' The basic workflow is:
#'  1. Update the metadata object
#'    1a. Make any changes to the metadata object that are desired
#'        (for example, convert from one metadata standard to another)
#'  2. Update the metadata object
#'  3. Update the resource map the metadata object is part of
#'
#'  A special note about this script: If the metadata object that's being
#'  updated is part of a set of nested data data packages, you'll want to
#'  insert these depth-first (children-first)
#'
#' This process and its functions use the existing Inventory structure, but
#' with one special modification:
#'
#' The $pid column is the new PID for the updated objects and a new column
#' is introduced $pid_old so that the correct linkages can be made.

# Load in vendored copies of rdataone and datapack

devtools::load_all(".")

# Set up the environment
Sys.setenv("ARCTICDATA_ENV"="development")
env <- env_load("etc/environment.yml")
env$mn <- MNode(env$mn_base_url)
env$base_path <- "~/src/arctic-data/arcticdata/inst/inventory_nested_iso/"
env$alternate_path <- "~/src/arctic-data/arcticdata/inst/inventory_nested_eml/"

# Load the inventory
inventory <- read.csv("inst/inventory_nested_iso/inventory_nested_iso.csv",
                      stringsAsFactors = FALSE)
inventory$pid <- sapply(1:nrow(inventory), function(x) { paste0("urn:uuid:", uuid::UUIDgenerate())})

for (d in seq(max(inventory$depth), min(inventory$depth))) {
  for (package in unique(inventory[inventory$depth == d,"package"])) {
    cat(paste0("Inserting package ", package, "\n"))

    last_insert <- insert_package(inventory, package, env)
    inventory <- inv_update(inventory, last_insert)
  }
}

# Bring in a list of new PIDs
inventory$pid_old <- inventory$pid
inventory[inventory$is_metadata,"pid"] <- sapply(1:nrow(inventory[inventory$is_metadata,]),
                                                 function(x) { paste0("urn:uuid:", uuid::UUIDgenerate())})
inventory$updated <- FALSE

# Insert
for (d in max(inventory$depth):min(inventory$depth)) {
  print(d)

  packages_at_depth <- unique(inventory[inventory$is_metadata & inventory$depth == d,"package"])

  for (package in packages_at_depth) {
    print(package)

    last <- update_package(inventory, package, env)
    inventory <- inv_update(inventory, last)
  }
}
