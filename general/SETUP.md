# Setup

This is installation guide for every instance that want to build server for coronator.

## Step

### Run setup script

Setup script is needed if you are deploying new compute instances.

```
sh setup.sh
```

### User creation

After running setup script, then the next step is you need to create new user.

```
adduser deployerbot
```

If you're finish, then add your user into docker user group

```bash
sudo usermod -aG sudo deployerbot
sudo usermod -aG docker deployerbot
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
