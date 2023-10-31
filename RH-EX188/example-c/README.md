# Example C

Example C creates two containers that use a volume to share a directory between the host and the containers. The first container writes a file with the date into the container, the second container reads the file and prints it to the console.

## Run

```bash
podman-compose up
```

## Stop

```bash
podman-compose down
```
