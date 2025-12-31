# Deploy

A bash script for packaging and deploying projects with a curl-to-bash command.

## Features

- Package directories for deployment
- Deploy packages with a single command
- Encryption for packaged files

## Installation

Install by running:

```bash
curl -sSL https://raw.githubusercontent.com/philiporange/deploy/refs/heads/main/deploy.sh | sudo bash -s install
```

## Usage

### Initialize configuration

```bash
deploy init
```

This will prompt you to enter the following information:

- **Backblaze B2 Bucket Name**: The name of the Backblaze B2 bucket where your packaged projects will be stored.
- **Backblaze B2 Bucket Endpoint**: The endpoint for your Backblaze B2 bucket. This is used to create the deployment command.
- **rclone destination**: The destination for `rclone` to upload the packaged project to. This should be in the format `remote:path`. For example, `b2:my-cool-bucket/deployments`.
- **Deploy script URL**: The URL of the `deploy.sh` script itself. This is used in the deployment one-liner. The default should be fine for most users.
- **rclone path**: The path to your `rclone` executable. The default should be fine for most users.

Your configuration will be saved to `$HOME/.config/remote_deploy.conf`. You can run `deploy init` again at any time to update your settings.

### Package a directory

```bash
deploy package /path/to/directory
```

After packaging, the command will return a one-liner that can be used for deploying the package.

### Deploy a package

```bash
deploy deploy <URL> <PASSWORD>
```

### Show help

```bash
deploy help
```

## License

This project is licensed under the Creative Commons Zero v1.0 Universal (CC0-1.0) License.
