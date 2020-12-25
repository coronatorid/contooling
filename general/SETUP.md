# Setup

This is installation guide for every instance that want to build server for coronator.

## Step

### Run setup script

Setup script is needed if you are deploying new compute instances.

```
sh setup.sh
```

### User creation

After running setup script, then the next step is you need to create new user. Follow this tutorial instead about how to create new user: [[Here](https://www.digitalocean.com/community/tutorials/how-to-create-a-new-sudo-enabled-user-on-ubuntu-20-04-quickstart)]. We suggest use `deployerbot` name.

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
