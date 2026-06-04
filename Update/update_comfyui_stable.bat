@echo off
setlocal

REM ==========================================
REM Portable ComfyUI Updater (uv-based)
REM ==========================================

set UV_CACHE_DIR=..\.cache\uv
set UV_NO_PROGRESS=1

set PYTHON_EXE=..\comfy_env\Scripts\python.exe

%PYTHON_EXE% .\update.py ..\ComfyUI\ --stable

if "%~1"=="" pause