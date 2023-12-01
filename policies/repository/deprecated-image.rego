package required_checks

violation_image_repository_deprecated[{"msg": msg, "details":{"name": name, "description": description, "url": url}}] {
  input.release_categories[_] == "Deprecated"

  name := "image_repository_deprecated"
  msg := "The container image shouldn't be built from a repository that is marked as 'Deprecated' in Red Hat Catalog."
  description := "Deprecated images are no longer maintained and will accumulate security vulnerabilities without releasing a fixed version."
  url := "https://redhat-connect.gitbook.io/catalog-help/container-images/container-image-details/container-image-release-categories"
}
