# Remote Deploy

A simple bash script for packaging and deploying directories to remote servers without needing to install additional software first.

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
