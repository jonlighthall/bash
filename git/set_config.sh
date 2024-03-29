#!/bin/bash -u

echo "setting Git user..."
git config --global user.name "Jon Lighthall"
git config --global user.email "jon.lighthall@gmail.com"

echo "setting Git preferences..."
git config --global color.ui true
git config core.fileMode false
git config --global core.autocrlf true
