# check_wp_new_users.sh

A shell script designed to monitor WordPress installations for newly created users. It integrates seamlessly with Nagios and provides critical status notifications when new users are detected. This script ensures secure handling of user data and supports validating changes when needed.

## Features

- Iterates through directories in a base directory to detect WordPress installations.
- Identifies and notifies about new users added to WordPress.
- Outputs in Nagios-compatible format:
  - `OK`: No new users detected.
  - `CRITICAL`: New users detected.
  - `WARNING`: Validation issues.
  - `UNKNOWN`: Script errors.
- Supports secure storage of user lists.
- Skips non-WordPress directories silently.
- Allows user list validation after detecting changes.

## Requirements

- Bash shell
- `wp-cli` installed and configured
- `jq` installed for JSON processing

## Installation

1. Download the script:

   ```bash
   curl -O https://example.com/check_wp_new_users.sh
   ```
2. Make it executable:

   ```bash
   chmod +x check_wp_new_users.sh
   ```
3. Ensure `wp-cli` and `jq` are installed:

   ```bash
   sudo apt-get install -y jq
   ```

## Usage

```bash
./check_wp_new_users.sh [OPTIONS]
```

### Options

- `--help`: Display the help message.
- `--validate`: Validate new users and update the stored user list.

## Example

### Checking for New Users

Run the script to check for new users:

```bash
./check_wp_new_users.sh
```
- Output:

  - `OK: No new users detected in any WordPress installation.`
  - `CRITICAL: New users detected in /var/www/site1: user1, user2`

### Validating Changes

After confirming changes, update the stored user list:

```bash
./check_wp_new_users.sh --validate
```
- Output:

  - `OK: User list in /var/www/site1 has been validated and updated.`

## How It Works

1. **WordPress Detection**: The script checks each directory for a WordPress installation using `wp core is-installed`.

2. **User List Comparison**: The script compares the current user list retrieved via `wp user list` with a previously stored list (`user_list.json`).

3. **New User Notification**: If new users are detected, the script outputs a critical status and saves the new list to `user_list_new.json` for validation.

4. **Validation**: The `--validate` option overwrites the old user list with the new one, confirming changes.

## Security

- User lists are stored securely with permissions set to `600` (read/write for root only).
- The script ensures secure handling by checking and setting permissions on stored files.

## Exit Codes

- `0` (OK): No new users detected.
- `1` (WARNING): Validation issues or pending changes.
- `2` (CRITICAL): New users detected.
- `3` (UNKNOWN): Script errors or misconfiguration.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

**Note:** Modify the `BASE_DIR` variable in the script to point to your WordPress installations directory (default: `/var/www`).
