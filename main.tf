resource "random_pet" "this" {
  length = 2
}

resource "google_storage_bucket" "this" {
  name               = "bucket-${random_pet.this.id}"
  bucket_policy_only = var.bucket_policy_only
}
