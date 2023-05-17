#!/bin/bash
curl wttr.in 2>&1 | sed "s/^/\x1b[40m/" 
