# Simple Terraform Tutorial Workshop for Google Cloud

In this workshop, we'll create a Google Cloud Storage bucket with Terraform.  For simplicity, we'll use local storage for the statefile. Local storage should only be used for light testing. For real-world usage, you should use a remote backend.

## Configure Google Cloud

Configure Google Cloud so Terraform can connect to it. The recommended way is to:

1. set up the `~/.gcp/credentials.json`
2. set up `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_PROJECT`, `GOOGLE_REGION`, and `GOOGLE_ZONE` environment variables

## Example

To configure your `GOOGLE_APPLICATION_CREDENTIALS` you need to set up a service account. Follow the Google [Getting Started with Authentication](https://cloud.google.com/docs/authentication/getting-started).

You'll download a JSON credentials file that looks something like the following. This is just an example:

~/.gcp/credentials.json

```json
{
  "type": "service_account",
  "project_id": "project-123456",
  "private_key_id": "06410f6eb4d7701419afbaceb21d9a239EXAMPLE",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...==\n-----END PRIVATE KEY-----\n",
  "client_email": "name@project-123456.iam.gserviceaccount.com",
  "client_id": "109186985834EXAMPLE",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/name%40project-123456.iam.gserviceaccount.com"
}
```

In your `~/.bashrc` or `~/.profile`, use these lines to set environment variables:

    export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/credentials.json
    # The rest of the environment variables are used by the Google terraform provider. See: https://www.terraform.io/docs/providers/google/guides/provider_reference.html#project-1
    export GOOGLE_PROJECT=$(cat ~/.gcp/credentials.json  | jq -r '.project_id')
    export GOOGLE_REGION=us-central1
    export GOOGLE_ZONE=us-central1-a

Note, it makes use of the `jq` command to grab the `GOOGLE_PROJECT` from the `credentials.json` file. You can either install jq or just add the actual value of your google project id.

## Test Google API Access

To check that GOOGLE_APPLICATION_CREDENTIALS is valid and is working you can use the [boltops-tools/google_check](https://github.com/boltops-tools/google_check) test script to check. Here are the summarized commands:

    git clone https://github.com/boltops-tools/google_check
    cd google_check
    bundle
    bundle exec ruby google_check.rb

You should see something like this:

    $ bundle exec ruby google_check.rb
    Listing gcs buckets as a test
    my-gcs-bucket
    Successfully connected to Google API with your GOOGLE_APPLICATION_CREDENTIALS
    $

Note, if there are no buckets in the project, then no buckets will be listed, but you'll still get a "Successfully connected" message

## Deploy

    terraform init
    terraform apply

Example with output:

    $ terraform apply

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:

      # google_storage_bucket.this will be created
      + resource "google_storage_bucket" "this" {
          + bucket_policy_only = false
          + force_destroy      = false
          + id                 = (known after apply)
          + location           = "US"
          + name               = (known after apply)
          + project            = (known after apply)
          + self_link          = (known after apply)
          + storage_class      = "STANDARD"
          + url                = (known after apply)
        }

      # random_pet.this will be created
      + resource "random_pet" "this" {
          + id        = (known after apply)
          + length    = 2
          + separator = "-"
        }

    Plan: 2 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

      Enter a value:

You're prompted to confirm. Type `yes` and press enter:

      Enter a value: yes

    random_pet.this: Creating...
    random_pet.this: Creation complete after 0s [id=whole-perch]
    google_storage_bucket.this: Creating...
    google_storage_bucket.this: Creation complete after 0s [id=bucket-whole-perch]

    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

    Outputs:

    url = gs://bucket-whole-perch

You can see a bucket was created.

## Explore

It is useful to explore some of the files that Terraform created. This helps understand what Terraform does and how it works.

The previous commands created a `.terraform` folder and a `terraform.tfstate` file.  They'll look something like this:

    ├── .terraform
    │   └── plugins
    │       └── linux_amd64
    │           ├── lock.json
    │           ├── terraform-provider-google_v3.31.0_x5
    │           └── terraform-provider-random_v2.3.0_x4
    └── terraform.tfstate

When you ran `terraform init`, terraform evaluated your Terraform code and detected that it needed to download the google and random provider plugins. This is how Terraform knows how to create the google resources.

Then when you ran `terraform apply` it applied the changes and created the Google Storage Bucket. Since we did not configure a backend.tf, the state information is stored locally in the `terraform.tfstate`. Go ahead and check out the contents of the file. Here's a `cat` command with `jq` to check out the file:

    cat terraform.tfstate | jq

Here's also relevant part of the statefile.

```json
{
...
  "resources": [
    {
      "mode": "managed",
      "type": "google_storage_bucket",
      "name": "this",
      "provider": "provider.google",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "bucket_policy_only": false,
            "cors": [],
            "default_event_based_hold": false,
            "encryption": [],
            "force_destroy": false,
            "id": "bucket-whole-perch",
            "labels": null,
            "lifecycle_rule": [],
            "location": "US",
            "logging": [],
            "name": "bucket-whole-perch",
            "project": "foobar-123456",
            "requester_pays": false,
            "retention_policy": [],
            "self_link": "https://www.googleapis.com/storage/v1/b/bucket-whole-perch",
            "storage_class": "STANDARD",
            "url": "gs://bucket-whole-perch",
            "versioning": [],
            "website": []
          },
          "private": "bnVsbA==",
          "dependencies": [
            "random_pet.this"
          ]
        }
      ]
    },
...
```

This is how terraform keeps track of what has been created and how to the manage the resources. As such, this is a crucial file.  In real-world usage, the statefile is stored in a remote backend like a GCS bucket and versioned.

## Cleanup

Let's clean up and delete the resources now.

    terraform destroy

You'll be prompted. Type `yes` to confirm.

Take another look at the `terraform.tfstate` file.

    cat terraform.tfstate | jq

You'll see something like this:

```json
{
  "version": 4,
  "terraform_version": "0.12.29",
  "serial": 6,
  "lineage": "e52eac51-f848-081f-0f26-fd3711354740",
  "outputs": {},
  "resources": []
}
```

You can see that the statefile also reflects that there are no resources.
