# Setup

This is installation guide for every instance that want to build server for coronator.

## Step

### Run setup script

Setup script is needed if you are deploying new compute instances.

```
sh setup.sh
```

### Setup SSH

Creating ssh directory of your newly created users

```bash
mkdir -p /home/deployerbot/.ssh
```

Copy public key into `.ssh/authorized_keys`.

After that, you need to edit your sshd config.

```
sudo nano /etc/ssh/sshd_config
```

Setup this variable

```
PasswordAuthentication no
PubkeyAuthentication yes
```

Then restart ssh service

```
sudo systemctl restart sshd
```
