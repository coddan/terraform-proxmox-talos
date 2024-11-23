terraform {
    backend "s3" {
        bucket = "terraform"                  # Name of the S3 bucket
        endpoints = {
          s3 = "http://192.168.1.5:20900"
        }
        key = "proxmox/proxmox-talos.tfstate"        # Name of the tfstate file

        region = "main"                     # Region validation will be skipped
        skip_credentials_validation = true  # Skip AWS related checks and validations
        skip_requesting_account_id = true
        skip_metadata_api_check = true
        skip_region_validation = true
        use_path_style = true             # Enable path-style S3 URLs (https://<HOST>/<BUCKET> https://developer.hashicorp.com/terraform/language/settings/backends/s3#use_path_style
    }
}
