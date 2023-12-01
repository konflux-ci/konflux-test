package required_checks

import data.repository as repository

test_violation_image_repository_deprecated {
    result := violation_image_repository_deprecated with input as repository
    result[_].details.name == "image_repository_deprecated"
    result[_].msg == "The container image shouldn't be built from a repository that is marked as 'Deprecated' in Red Hat Catalog."
    result[_].details.url == "https://redhat-connect.gitbook.io/catalog-help/container-images/container-image-details/container-image-release-categories"
}
