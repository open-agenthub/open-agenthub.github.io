# Quickstart k3s version

The Linux installer pins `v1.36.5+k3s1`, verified by the install gate including upgrade in place. An unpinned stable channel was rejected because a channel service outage prevented fresh installations even while release downloads remained available. `AGENTHUB_K3S_VERSION` overrides the pin for deliberate testing; existing clusters are reused without upgrading k3s.

To bump, change the default in `install.sh`, then dispatch the main repository’s Quickstart install workflow with `installer_ref` set to the website branch or commit and `block_k3s_channel=true`. Require installation, smoke tests and upgrade in place to pass before merging the website change. Update this document with the tested version. Normal gate runs consume the published installer and therefore share its pin.
