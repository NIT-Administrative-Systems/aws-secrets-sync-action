variable "local_state_passphrase" {
    sensitive   = true
    type        = string
    nullable    = false
    description = "Passphrase for this module's state encryption"

    validation {
        condition = length(var.local_state_passphrase) == 32
        error_message = "AES-GCM key should be 32 bytes"
    }
}

terraform {
    encryption {
        key_provider "pbkdf2" "local_state_passphrase" {
            passphrase    = var.local_state_passphrase
            key_length    = 32
            iterations    = 600000
            salt_length   = 32
            hash_function = "sha512"
        }

        method "aes_gcm" "local-state-encryption" {
            keys = key_provider.pbkdf2.local_state_passphrase
        }

        method "unencrypted" "migrate" {
            # Used as a fallback for the initial state of a previously-unencrypted project.
            # This does not need to be included for brand-new projects that start out encrypted.
        }

        # This is YOUR module's state.
        state {
            method = method.aes_gcm.local-state-encryption

            # Only needed for a pre-existing Terraform project, which has an unencrypted state file.
            # Once this has run for every environment, the fallback can be removed, and the
            # enforced = true option can be enabled.
            fallback {
                method = method.unencrypted.migrate
            }

            # Enable this when all envs have been moved to encrypted state. It prevents accidentally writing
            # an unencrypted state file, if the passphrase var is unset for some reason.
            #
            # enforced = true
        }
    }
}
