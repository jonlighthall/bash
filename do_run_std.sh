#!/bin/bash
PROGRAM=$PWD/nspe.exe
STD_DIR=stdcpy

rm -v $STD_DIR/case*.003
rm -v $STD_DIR/case*.asc
rm -v $STD_DIR/case*.dat
rm -v $STD_DIR/case*.log

$PROGRAM $STD_DIR/case1r.in
$PROGRAM $STD_DIR/case2r.in
$PROGRAM $STD_DIR/case3r.in
$PROGRAM $STD_DIR/case4r.in
$PROGRAM $STD_DIR/case5r.in
$PROGRAM $STD_DIR/case6r.in
$PROGRAM $STD_DIR/case7r.in
$PROGRAM $STD_DIR/case8r.in
$PROGRAM $STD_DIR/case9r.in
$PROGRAM $STD_DIR/case10Ar.in
$PROGRAM $STD_DIR/case10Br.in
$PROGRAM $STD_DIR/case10C.in
$PROGRAM $STD_DIR/case10Cr.in
$PROGRAM $STD_DIR/case10Dr.in
$PROGRAM $STD_DIR/case10Er.in
$PROGRAM $STD_DIR/case10Fr.in
$PROGRAM $STD_DIR/case11r.in
