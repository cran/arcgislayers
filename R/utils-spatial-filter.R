#' Prepare JSON for use as a spatial filter based on feature geometry or
#' bounding box input
#'
#' [prepare_spatial_filter()] prepares a named list with ESRI JSON geometry for
#' use as a spatial filter based on a a `sfc`, `sfg`, or `bbox` input object.
#'
#' @inheritParams arcgisutils::validate_crs
#' @param filter_geom an object of class `bbox`, `sfc` or `sfg` used to filter
#'   query results based on a predicate function.
#' @param predicate Spatial predicate to use with `filter_geom`. Default
#'   `"intersects"`. Possible options are `"intersects"`, `"contains"`,
#'   `"crosses"`,  `"overlaps"`,  `"touches"`, and `"within"`.
#' @param error_call default `rlang::caller_env()`.
#'
#' @details Using `sfc` objects as `filter_geom`
#'
#' `r lifecycle::badge("experimental")`
#'
#'  If an `sfc` object is provided it will be transformed to the layers spatial
#'  reference. If the `sfc` is missing a CRS (or is an `sfg` object) it is
#'  assumed to use the same spatial reference as the FeatureLayer. If the `sfc`
#'  object has multiple features, the features are unioned with
#'  [sf::st_union()]. If an `sfc` object has `MULTIPOLYGON` geometry, the features
#'  are unioned before being cast to `POLYGON` geometry with [sf::st_cast()]. All
#'  geometries are checked for validity before conversion.
#'
#' @returns [prepare_spatial_filter()] returns a named list with the
#'   `geometryType`, `geometry` (as Esri JSON), and spatial relation predicate.
#'
#' @rdname spatial_filter
#' @examples
#' prepare_spatial_filter(sf::st_point(c(0, 5)), 4326, "intersects")
#' @export
prepare_spatial_filter <- function(
    filter_geom,
    crs,
    predicate,
    error_call = rlang::caller_env()
) {

  check_inherits_any(
    filter_geom,
    class = c("sfc", "sfg", "bbox"),
    call = error_call
  )

  # NOTE: CRS cannot be missing
  if (inherits(filter_geom, "bbox")) {
    filter_geom <- sf::st_as_sfc(filter_geom)
  } else if (any(!sf::st_is_valid(filter_geom))) {
    filter_geom <- sf::st_make_valid(filter_geom)
  }

  # FIXME: Unsure how to handle sfg inputs w/o checking CRS
  if (inherits(filter_geom, "sfg")) {
    filter_crs <- crs
  } else {
    filter_crs <- sf::st_crs(filter_geom)

    if (is.na(filter_crs)) {
      filter_crs <- crs
    }
  }

  # if an sfc_multipolygon we union and cast to polygon
  # related issue: https://github.com/R-ArcGIS/arcgislayers/issues/4
  if (inherits(filter_geom, "sfc_MULTIPOLYGON")) {
    cli::cli_inform(
      c(
        "!" = "{.arg filter_geom} cannot be a {.val MULTIPOLYGON} geometry.",
        "i" = "Using {.fn sf::st_union} and {.fn sf::st_cast} to create a
        {.val POLYGON} for {.arg filter_geom}."
      ),
      call = error_call
    )
    filter_geom <- sf::st_union(filter_geom)
    filter_geom <- sf::st_cast(filter_geom, to = "POLYGON")
  } else if (inherits(filter_geom, "MULTIPOLYGON")) {
    filter_geom <- sf::st_cast(filter_geom, "POLYGON")
  }

  # if its an sfc object it must be length one
  if (inherits(filter_geom, "sfc")) {
    if (length(filter_geom) > 1) {
      filter_geom <- sf::st_union(filter_geom)
    }
    # extract the sfg object which is used to write Esri json
    filter_geom <- filter_geom[[1]]
  }

  list(
    geometryType = arcgisutils::determine_esri_geo_type(filter_geom),
    geometry = arcgisutils::as_esri_geometry(filter_geom, crs = filter_crs),
    spatialRel = match_spatial_rel(predicate, error_call = error_call)
    # TODO is `inSR` needed if the CRS is specified in the geometry???
  )
}

#' @description
#' [match_spatial_rel()] takes a scalar character vector with a predicate name
#' to a type of ESRI spatial relation.
#'
#' @returns [match_spatial_rel()] returns one of the following spatial binary predicates:
#'
#' - esriSpatialRelIntersects
#' - esriSpatialRelContains
#' - esriSpatialRelCrosses
#' - esriSpatialRelOverlaps
#' - esriSpatialRelTouches
#' - esriSpatialRelWithin
#'
#' @export
#' @rdname spatial_filter
match_spatial_rel <- function(predicate, error_call = rlang::caller_env()) {
  # determine the spatial relationship (predicate)
  esri_predicates <- c(
    # Part of a feature from the query feature is contained in a feature from
    # target feature
    "esriSpatialRelIntersects",
    # Part or all of a feature from a query feature is contained within a
    # feature from target feature
    "esriSpatialRelContains",
    # feature from a query feature crosses a feature from target feature
    "esriSpatialRelCrosses",
    # envelope of the query feature intersects with the envelope of target
    # feature
    # "esriSpatialRelEnvelopeIntersects",
    # envelope of the query feature intersects the index entry for the target
    # feature
    # "esriSpatialRelIndexIntersects",
    # Features from the query feature overlap features in target feature
    "esriSpatialRelOverlaps",
    # feature from the query feature touches the border of a feature from target
    # feature
    "esriSpatialRelTouches",
    # feature from the query feature is completely enclosed by the feature from
    # target feature
    "esriSpatialRelWithin"
  )

  pred_arg_vals <- tolower(
    substr(esri_predicates, 15, nchar(esri_predicates))
  )

  # ensure a correct one has been chosen
  predicate <- tolower(predicate)
  predicate <- rlang::arg_match(predicate, pred_arg_vals, error_call = error_call)

  esri_predicates[grepl(predicate, esri_predicates, ignore.case = TRUE)]
}
