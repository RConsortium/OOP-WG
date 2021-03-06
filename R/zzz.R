#' An R7 object
#' @export
R7_object <- new_class(
  name = "R7_object",
  parent = NULL,
  constructor = function() {
     out <- .Call(R7_object_)
     class(out) <- "R7_object"
     out
  }
)

base_classes <- new.env(parent = emptyenv())
base_classes[["logical"]] <- new_class("logical", constructor = function(x = logical()) new_object(x))
base_classes[["integer"]] <- new_class("integer", constructor = function(x = integer()) new_object(x))
base_classes[["double"]] <- new_class("double", constructor = function(x = double()) new_object(x))
base_classes[["numeric"]] <- new_class("numeric", constructor = function(x = numeric()) new_object(x))
base_classes[["complex"]] <- new_class("complex", constructor = function(x = complex()) new_object(x))
base_classes[["character"]] <- new_class("character", constructor = function(x = character()) new_object(x))
base_classes[["factor"]] <- new_class("factor", constructor = function(x = factor()) new_object(x))
base_classes[["raw"]] <- new_class("raw", constructor = function(x = raw()) new_object(x))
base_classes[["function"]] <- new_class("function", constructor = function(x = function() NULL) new_object(x))
base_classes[["list"]] <- new_class("list", constructor = function(x = list()) new_object(x))
base_classes[["data.frame"]] <- new_class("data.frame", constructor = function(x = data.frame()) new_object(x))
base_classes[["NULL"]] <- new_class("NULL", constructor = function(x = NULL) new_object(x))

#' R7 generics and method objects
#' @param name,generic The name or generic object of the generic
#' @param signature The signature of the generic
#' @param fun The function to use as the body of the generic.
#' @export
R7_generic <- new_class(
  name = "R7_generic",
  properties = list(name = "character", methods = "environment", signature = new_property(name = "signature", getter = function(x) formals(x@.data))),
  parent = "function",
  constructor = function(name, signature, fun) {
    new_object(name = name, signature = signature, methods = new.env(parent = emptyenv(), hash = TRUE), .data = fun)
  }
)

#' @rdname R7_generic
#' @export
R7_method <- new_class(
  name = "R7_method",
  properties = list(generic = "R7_generic", signature = "list", fun = "function"),
  parent = "function",
  constructor = function(generic, signature, fun) {
    if (is.character(signature)) {
      signature <- list(signature)
    }
    new_object(generic = generic, signature = signature, .data = fun)
  }
)

#' Class unions
#'
#' A class union represents a list of possible classes. It is used in
#' properties to allow a property to be one of a set of classes, and in method
#' dispatch as a convenience for defining a method for multiple classes.
#' @param ... The classes to include in the union, either looked up by named or
#'   by passing the `R7_class` objects directly.
#' @export
R7_union <- new_class(
  name = "R7_union",
  properties = list(classes = "list"),
  validator = function(x) {
    for (val in x@classes) {
      if (!inherits(val, "R7_class")) {
        return(sprintf("All classes in an <R7_union> must be R7 classes:\n - <%s> is not an <R7_class>", class(val)[[1]]))
      }
    }
  },
  constructor = function(...) {
    classes <- list(...)
    for (i in seq_along(classes)) {
      if (is.character(classes[[i]])) {
        classes[[i]] <- class_get(classes[[i]])
      }
    }

    new_object(classes = classes)
  }
)

#' @rdname R7_union
#' @export
new_union <- R7_union


global_variables(c("name", "parent", "properties", "constructor", "validator"))

.onAttach <- function(libname, pkgname) {
  env <- as.environment(paste0("package:", pkgname))
  env[[".conflicts.OK"]] <- TRUE
}
