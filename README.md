# Deploy

A bash script for packaging and deploying projects to with a one-line curl-to-bash command.

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
