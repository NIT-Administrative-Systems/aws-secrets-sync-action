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

        # This is YOUR module's state.
        state {
            method = method.aes_gcm.local-state-encryption

            enforced = true
        }
    }
}
