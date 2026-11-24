# Auth, one of:
#   - service account key: NEBIUS_SA_ID, NEBIUS_SA_PUBLIC_KEY_ID, NEBIUS_SA_PRIVATE_KEY_FILE
#   - user token:          NEBIUS_IAM_TOKEN (takes precedence if set)
provider "nebius" {
  parent_id = var.project_id

  service_account = {
    account_id_env       = "NEBIUS_SA_ID"
    public_key_id_env    = "NEBIUS_SA_PUBLIC_KEY_ID"
    private_key_file_env = "NEBIUS_SA_PRIVATE_KEY_FILE"
  }
}
