package main

deny[msg] {
    input.release_categories[_] == "Deprecated"
    msg := "Image is deprecated"
}
