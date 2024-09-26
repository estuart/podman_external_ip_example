You can add logic to a systemd unit file to dynamically determine the external IP address of your host. To achieve this, you can use ExecStartPre to run a script that discovers the external IP and passes it to the container runtime as an argument.

Here’s how you can do it:

### 1. Create a Script to Determine the External IP

First, create a script that finds your host’s external IP address. For example, you could use a command like curl to query an external service (e.g., ifconfig.me or ipinfo.io), or use ip or ifconfig to get the IP assigned to a specific network interface.

Here’s a simple script (/usr/local/bin/get_external_ip.sh) that retrieves the external IP using the `ip` command which doesn't require internet access:

```
#!/bin/bash

# Get the IP address of a specific interface (e.g., eth0)
ip -o -4 addr show eth0 | awk '{print $4}' | cut -d/ -f1
```
Make the script executable
```
sudo chmod +x /usr/local/bin/get_external_ip.sh
```

### 2. Create a systemd unit file
Now, create your systemd unit file to incorporate this script. You can use ExecStartPre to run the script, store the external IP in a temporary environment variable, and pass it to ExecStart for running the container.

Here is an example of what your systemd unit file would look like:
```
[Unit]
Description=My Container Service with Dynamic External IP Binding
After=network.target

[Service]
# Run a pre-start script to get the external IP
ExecStartPre=/bin/bash -c 'EXTERNAL_IP=$(/usr/local/bin/get_external_ip.sh); echo $EXTERNAL_IP > /run/external_ip'
# Start the container, binding it to the discovered external IP
ExecStart=/bin/bash -c '/usr/bin/podman run --rm -p $(cat /run/external_ip):80:80 my_container_image'
Restart=always

[Install]
WantedBy=multi-user.target
```
Explanation:
  - `ExecStartPre`: This command runs before the main ExecStart. It calls your script to get the external IP and writes it to a file (/run/external_ip). This file is then read by the ExecStart command.
  - `ExecStart`: This command runs the container with the external IP dynamically loaded by reading from the /run/external_ip file.
  - `Restart=always`: This ensures that the service restarts automatically if it crashes or stops.

Store this file under the `/etc/systemd/system/` directory. In this case I'm naming this file my_container.service so the full path would be `/etc/systemd/system/my_container.service`
### 3. Reload and Restart the Service
After creating your unit file reload `systemd` and start and enable the service
```
sudo systemctl daemon-reload
sudo systemctl enable my_container.service
sudo systemctl restart my_container.service
```
