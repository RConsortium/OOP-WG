#' Define a new property
#'
#' @param name The name of the property
#' @param class The class of the property
#' @param getter An optional function used to get the value. The function
#'   should take the object as its sole argument and return the value. If the
#'   property has a `class` the class of the value is validated.
#' @param setter An optional function used to set the value. The function
#'   should take the object and new value as its two parameters and return the
#'   modified object. The value is _not_ automatically checked.
#' @export
new_property <- function(name, class = NULL, getter = NULL, setter = NULL) {
  out <- list(name = name, class = class, getter = getter, setter = setter)
  class(out) <- "R7_property"

  out
}

#' Extract or replace a property
#'
#' - [property] or the shorthand `@` extracts a given property, throwing an error if the property doesn't exist for that object.
#' - [property_safely] returns `NULL` if a property doesn't exist, rather than throwing an error.
#' - [property<-] assigns a new value for a given property.
#' @param object An object from a R7 class
#' @param name The name of the parameter as a character. No partial matching is done.
#' @param value A replacement value for the parameter. The object is
#'   automatically checked for validity after the replacement is done.
#' @export
property <- function(object, name) {
  val <- property_safely(object, name)
  if (is.null(val)) {
    class <- object_class(object)
    stop(sprintf("Can't find property %s@%s", fmt_classes(class@name), name), call. = FALSE)
  }

  val
}

#' @rdname property
#' @export
property_safely <- function(object, name) {
  if (!inherits(object, "R7_object")) {
    return(NULL)
  }
  if (identical(name, ".data")) {
    # Remove properties, return the rest
    props <- properties(object)
    for (name in names(props)) {
      attr(object, name) <- NULL
    }
    obj_cls <- object_class(object)
    class(object) <- setdiff(class_names(obj_cls@parent), obj_cls@name)
    object_class(object) <- object_class(obj_cls@parent)
    return(object)
  }
  val <- attr(object, name, exact = TRUE)
  if (is.null(val)) {
    prop <- properties(object)[[name]]
    if (!is.null(prop$getter)) {
      val <- prop$getter(object)
    }
  }
  val
}

properties <- function(object) {
  obj_class <- object_class(object)
  prop <- list()
  while(!is.null(obj_class)) {
    prop <- c(attr(obj_class, "properties"), prop)
    obj_class <- attr(obj_class, "parent", exact = TRUE)
  }

  prop
}

#' @rdname property
#' @param check If `TRUE`, check that `value` is of the correct type and run
#'   [validate()] on the object before returning.
#' @export
`property<-` <- local({
  # This flag is used to avoid infinate loops if you are assigning a property from a setter function
  setter_property <- NULL

  function(object, name, check = TRUE, value) {
    if (name == ".data") {
      attrs <- attributes(object)
      object <- value
      attributes(object) <- attrs
      if (isTRUE(check)) {
        validate(object)
      }
      return(invisible(object))
    }

    prop <- properties(object)[[name]]
    if (!is.null(prop$setter) && !identical(setter_property, name)) {
      setter_property <<- name
      on.exit(setter_property <<- NULL, add = TRUE)
      object <- prop$setter(object, value)
    } else {
      if (isTRUE(check) && length(prop[["class"]]) > 0) {
        classes <- setdiff(class_names(prop[["class"]]), "R7_object")
        if (!inherits(value, classes)) {
          obj_cls <- object_class(object)
          stop(sprintf("%s@%s must be of class %s:\n- `value` is of class <%s>", fmt_classes(obj_cls@name), name, fmt_classes(classes), class(value)[[1]]), call. = FALSE)
        }
      }
      attr(object, name) <- value
    }

    if (isTRUE(check)) {
      validate(object)
    }

    invisible(object)
  }
})

#' @rdname property
#' @usage object@name
#' @export
`@` <- function(object, name) {
  if (!inherits(object, "R7_object")) {
    if (is.null(object)) {
      return()
    }
    name <- substitute(name)
    return(do.call(base::`@`, list(object, name)))
  }

  nme <- as.character(substitute(name))
  property(object, nme)
}

#' @rawNamespace S3method("@<-",R7_object)
`@<-.R7_object` <- function(object, name, value) {
  if (!inherits(object, "R7_object")) {
    return(base::`@<-`(object, name))
  }

  nme <- as.character(substitute(name))
  property(object, nme) <- value

  invisible(object)
}

as_properties <- function(x) {
  if (length(x) == 0) {
    return(x)
  }

  named_chars <- vlapply(x, is.character) & has_names(x)
  R7_properties <- vlapply(x, inherits, "R7_property")

  if (!all(named_chars | R7_properties)) {
    stop("`x` must be a list of 'R7_property' objects or named characters", call. = FALSE)
  }

  x[named_chars] <- mapply(new_property, name = names(x)[named_chars], class = x[named_chars], USE.NAMES = TRUE, SIMPLIFY = FALSE)

  names(x)[!named_chars] <- vcapply(x[!named_chars], function(x) x[["name"]])

  x
}
