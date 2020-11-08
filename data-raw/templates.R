## WL License
license <- readLines('data-raw/templates/LICENSE.txt')
usethis::use_data(license, compress = 'xz', overwrite = TRUE)

## connect template
connect_template <- readLines('data-raw/templates/connect_template.txt')
usethis::use_data(connect_template, compress = 'xz', overwrite = TRUE)

## table template
table_template <- readLines('data-raw/templates/table_template.txt')
usethis::use_data(table_template, compress = 'xz', overwrite = TRUE)

## item template
item_template <- readLines('data-raw/templates/item_template.txt')
usethis::use_data(item_template, compress = 'xz', overwrite = TRUE)

