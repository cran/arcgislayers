# These tests test that the service can be read correctly.
# can be improved to check attributes like query, class, etc.

test_that("arc_open(): Feature Layer", {
  ft_url <- "https://services.arcgis.com/P3ePLMYs2RVChkJx/ArcGIS/rest/services/USA_Counties_Generalized_Boundaries/FeatureServer/0"

  lyr <- arc_open(ft_url)

  expect_no_error(lyr)

  ft_query_url <- "https://services.arcgis.com/P3ePLMYs2RVChkJx/ArcGIS/rest/services/USA_Counties_Generalized_Boundaries/FeatureServer/0/query?outFields=%2A&where=1%3D1"

  lyr_q <- arc_open(ft_query_url)

  expect_identical(lyr, lyr_q)
})


test_that("arc_open(): Table", {

  tbl_url <- "https://services2.arcgis.com/j80Jz20at6Bi0thr/ArcGIS/rest/services/List_of_Providers/FeatureServer/27"

  expect_no_error(arc_open(tbl_url))
})

test_that("arc_open(): Feature Server", {

  server_url <- "https://services2.arcgis.com/j80Jz20at6Bi0thr/ArcGIS/rest/services/hexagons_state/FeatureServer"
  expect_no_error(arc_open(server_url))

})

test_that("arc_open(): Map Server", {
  map_url <- paste0(
    "https://services.arcgisonline.com/ArcGIS/rest/services/",
    "World_Imagery/MapServer"
  )

  expect_no_error(arc_open(map_url))
})

test_that("arc_open(): Image Server", {
  img_url <- "https://landsat2.arcgis.com/arcgis/rest/services/Landsat/MS/ImageServer"

  expect_no_error(arc_open(img_url))
})

test_that("arc_open(): GroupLayer", {
  gurl <- "https://geodata.baltimorecity.gov/egis/rest/services/CitiMap/DOT_Layers/MapServer/0"
  expect_no_error(arc_open(gurl))
})

test_that("arc_open(): doesn't filter NULL properties", {

  furl <- "https://geodata.md.gov/imap/rest/services/Transportation/MD_Transit/FeatureServer/8"

  flayer <- arc_open(furl)

  expect_identical(length(flayer), 56L)
})
