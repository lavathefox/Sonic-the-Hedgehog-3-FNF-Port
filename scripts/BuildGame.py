#!/usr/bin/env python3
import argparse
import os
import platform
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

TARGETS = ('windows', 'linux', 'mac', 'android', 'html5')
MODES = ('debug', 'release')
COMMANDS = ('build', 'test', 'run', 'clean', 'setup', 'doctor')


def find_root(start):
    current = start.resolve()
    for directory in (current, *current.parents):
        if (directory / 'Project.xml').is_file():
            return directory
    return None


def detect_target():
    name = platform.system().lower()
    return {'windows': 'windows', 'linux': 'linux', 'darwin': 'mac'}.get(name, 'html5')


def check_command(command):
    return shutil.which(command) is not None


def timestamp():
    return datetime.now().strftime('%Y-%m-%d_%H-%M-%S')


def doctor(root, target):
    print(f'Project: {root}')
    print(f'Host: {platform.system()} {platform.machine()}')
    print(f'Target: {target}')
    print(f'Python: {sys.version.split()[0]}')
    for program in ('haxe', 'haxelib', 'lime', 'java', 'git'):
        location = shutil.which(program)
        print(f'{program}: {location or "NOT FOUND"}')
    print(f'Project.xml: {"OK" if (root / "Project.xml").is_file() else "NOT FOUND"}')
    if target == 'android':
        for name in ('ANDROID_HOME', 'ANDROID_SDK_ROOT', 'ANDROID_NDK_ROOT', 'JAVA_HOME'):
            print(f'{name}: {os.environ.get(name) or "not set"}')
    if target == 'windows' and platform.system() != 'Windows':
        print('Note: Windows cross-compilation requires a compatible toolchain.')
    if target == 'mac' and platform.system() != 'Darwin':
        print('Note: macOS builds normally require macOS and Xcode.')
    if target == 'android':
        print('Note: Android requires a configured Android SDK, NDK and Java environment.')


def build_command(args):
    if args.command == 'setup':
        return ['haxelib', 'run', 'lime', 'setup', args.target]
    command = ['haxelib', 'run', 'lime', args.command, args.target]
    if args.mode == 'debug' and args.command != 'clean':
        command.append('-debug')
    if args.command in ('build', 'test', 'run'):
        if args.clean_first:
            command.append('-clean')
        if args.define:
            for definition in args.define:
                command.extend(['-D', definition])
    if args.extra:
        command.extend(args.extra)
    return command


def execute(command, root, quiet, logfile, dry_run, environment):
    print('Command:', ' '.join(command))
    print('Working directory:', root)
    if dry_run:
        print('Dry run: command not executed.')
        return 0
    logfile.parent.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    try:
        with logfile.open('w', encoding='utf-8', errors='replace') as output:
            output.write('Command: ' + ' '.join(command) + '\n')
            output.write('Started: ' + datetime.now().isoformat() + '\n\n')
            output.flush()
            process = subprocess.Popen(
                command, cwd=str(root), env=environment,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, encoding='utf-8', errors='replace', bufsize=1
            )
            try:
                for line in process.stdout:
                    output.write(line)
                    if not quiet:
                        print(line, end='', flush=True)
                return_code = process.wait()
            except KeyboardInterrupt:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                print('\nBuild interrupted.', file=sys.stderr)
                return_code = 130
            elapsed = time.monotonic() - started
            output.write(f'\nExit code: {return_code}\nElapsed: {elapsed:.1f}s\n')
    except OSError as error:
        print(f'Unable to start build: {error}', file=sys.stderr)
        return 127
    print(f'{"SUCCESS" if return_code == 0 else "FAILED"} ({elapsed:.1f}s)')
    print(f'Log: {logfile}')
    if quiet and return_code != 0:
        print('Last log lines:', file=sys.stderr)
        try:
            lines = logfile.read_text(encoding='utf-8', errors='replace').splitlines()
            for line in lines[-35:]:
                print(line, file=sys.stderr)
        except OSError:
            pass
    return return_code


def parse_args():
    parser = argparse.ArgumentParser(
        description='Sonic 3 FNF Port build manager for Lime/OpenFL.'
    )
    parser.add_argument('command', nargs='?', choices=COMMANDS, default='build')
    parser.add_argument('target', nargs='?', choices=TARGETS, default=detect_target())
    parser.add_argument('--mode', choices=MODES, default='release')
    parser.add_argument('--debug', action='store_true', help='Shortcut for --mode debug')
    parser.add_argument('--release', action='store_true', help='Shortcut for --mode release')
    parser.add_argument('--quiet', '-q', action='store_true', help='Only show status and errors')
    parser.add_argument('--clean-first', action='store_true', help='Request a clean build')
    parser.add_argument('-D', '--define', action='append', help='Additional Haxe define')
    parser.add_argument('--log-dir', type=Path, default=Path('build_logs'))
    parser.add_argument('--root', type=Path, help='Project directory containing Project.xml')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--extra', nargs=argparse.REMAINDER, help='Arguments passed to Lime (place last)')
    args = parser.parse_args()
    if args.debug and args.release:
        parser.error('--debug and --release cannot be used together')
    if args.debug:
        args.mode = 'debug'
    if args.release:
        args.mode = 'release'
    return args


def main():
    args = parse_args()
    root = find_root(args.root or Path(__file__).resolve().parent)
    if root is None:
        print('ERROR: Project.xml not found. Use --root PATH.', file=sys.stderr)
        return 2
    if args.command == 'doctor':
        doctor(root, args.target)
        return 0 if check_command('haxelib') and check_command('haxe') else 1
    if not check_command('haxelib') and not args.dry_run:
        print('ERROR: haxelib not found in PATH. Install Haxe first.', file=sys.stderr)
        return 127
    if args.command == 'setup' and args.target == 'html5':
        print('Note: HTML5 usually does not need a separate platform setup.')
    command = build_command(args)
    log_dir = args.log_dir if args.log_dir.is_absolute() else root / args.log_dir
    log = log_dir / f'{args.command}_{args.target}_{args.mode}_{timestamp()}.log'
    env = os.environ.copy()
    return execute(command, root, args.quiet, log, args.dry_run, env)


if __name__ == '__main__':
    sys.exit(main())
