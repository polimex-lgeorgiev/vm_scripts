#!/bin/bash

ssh-keygen -t ed25519 -C "support@polimex.co"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
echo "Add this token to github"
cat ~/.ssh/id_ed25519.pub