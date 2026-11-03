#!/usr/bin/env python3
import argparse
import os
import platform
import shutil
import subprocess
import sys
import time
from collections import deque
from datetime import datetime
from pathlib import Path

TARGETS = ('windows', 'linux', 'mac', 'android', 'html5')
COMMANDS = ('build', 'test', 'run', 'clean', 'setup', 'doctor')
PROJECT_FILE = 'project.xml'


def detect_target():
    return {'Windows': 'windows', 'Linux': 'linux', 'Darwin': 'mac'}.get(platform.system(), 'html5')


def find_root(start):
    location = Path(start).expanduser().resolve()
    if location.is_file():
        location = location.parent
    for directory in (location, *location.parents):
        if (directory / PROJECT_FILE).is_file():
            return directory
    return None


def now():
    return datetime.now().strftime('%Y%m%d_%H%M%S_%f')


def cli():
    parser = argparse.ArgumentParser(description='Build manager for Sonic 3 FNF Port (Lime/OpenFL).')
    parser.add_argument('command', nargs='?', choices=COMMANDS, default='build')
    parser.add_argument('target', nargs='?', choices=TARGETS, default=detect_target())
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--debug', action='store_true')
    mode.add_argument('--release', action='store_true')
    parser.add_argument('--mode', choices=('debug', 'release'), default=None)
    parser.add_argument('-q', '--quiet', action='store_true')
    parser.add_argument('--clean-first', action='store_true')
    parser.add_argument('-D', '--define', action='append', default=[])
    parser.add_argument('--root', type=Path)
    parser.add_argument('--log-dir', type=Path, default=Path('build_logs'))
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--timeout', type=float, default=0, help='Maximum seconds per command; 0 disables timeout')
    parser.add_argument('--tail', type=int, default=45, help='Number of log lines printed on failure in quiet mode')
    parser.add_argument('--no-color', action='store_true')
    parser.add_argument('--extra', nargs=argparse.REMAINDER, default=[])
    args = parser.parse_args()
    if args.mode and ((args.debug and args.mode != 'debug') or (args.release and args.mode != 'release')):
        parser.error('Conflicting build modes')
    if args.timeout < 0 or args.tail < 0:
        parser.error('--timeout and --tail must not be negative')
    args.mode = 'debug' if args.debug else 'release' if args.release else (args.mode or 'release')
    if args.extra and args.extra[0] == '--':
        args.extra.pop(0)
    if args.command in ('doctor', 'setup', 'clean') and args.clean_first:
        parser.error('--clean-first is only valid for build, test, or run')
    return args


def lime_command(args, command):
    if command == 'setup':
        return ['haxelib', 'run', 'lime', 'setup', args.target]
    result = ['haxelib', 'run', 'lime', command, args.target]
    if args.mode == 'debug' and command in ('build', 'test', 'run'):
        result.append('-debug')
    if command in ('build', 'test', 'run'):
        for define in args.define:
            result.extend(['-D', define])
        result.extend(args.extra)
    return result


def diagnose(root, target):
    print('Project:', root)
    print('Project file:', root / PROJECT_FILE)
    print('Host:', platform.platform())
    print('Target:', target)
    print('Python:', sys.version.split()[0])
    missing = []
    for command in ('haxe', 'haxelib', 'java', 'git'):
        path = shutil.which(command)
        print(f'{command}: {path or "NOT FOUND"}')
        if command in ('haxe', 'haxelib') and not path:
            missing.append(command)
    if target == 'android':
        for name in ('ANDROID_HOME', 'ANDROID_SDK_ROOT', 'ANDROID_NDK_ROOT', 'ANDROID_NDK_HOME', 'JAVA_HOME'):
            print(f'{name}: {os.environ.get(name) or "not set"}')
        if not shutil.which('java'):
            missing.append('java')
        print('Android requires compatible SDK, NDK, JDK and Lime setup.')
    if target == 'mac' and platform.system() != 'Darwin':
        print('macOS builds normally require a macOS host.')
    if target == 'windows' and platform.system() != 'Windows':
        print('Windows cross-compilation requires an appropriate toolchain.')
    if missing:
        print('Missing required tools:', ', '.join(missing), file=sys.stderr)
        return 1
    return 0


def run(command, root, log, quiet, dry_run, timeout, tail):
    print('>', subprocess.list2cmdline(command) if os.name == 'nt' else __import__('shlex').join(command), flush=True)
    if dry_run:
        print('Dry run: no command executed.')
        return 0
    log.parent.mkdir(parents=True, exist_ok=True)
    recent = deque(maxlen=max(1, tail))
    start = time.monotonic()
    code = 127
    try:
        with log.open('w', encoding='utf-8', errors='replace') as output:
            output.write('Command: ' + repr(command) + '\n')
            output.write('Directory: ' + str(root) + '\n')
            output.write('Started: ' + datetime.now().isoformat() + '\n\n')
            output.flush()
            with subprocess.Popen(command, cwd=str(root), stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT, text=True, encoding='utf-8',
                                  errors='replace', bufsize=1) as process:
                try:
                    for line in process.stdout:
                        output.write(line)
                        output.flush()
                        recent.append(line.rstrip('\n'))
                        if not quiet:
                            print(line, end='', flush=True)
                        if timeout and time.monotonic() - start > timeout:
                            raise TimeoutError(f'Build exceeded {timeout:g} seconds')
                    code = process.wait()
                except (KeyboardInterrupt, TimeoutError) as error:
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    code = 130 if isinstance(error, KeyboardInterrupt) else 124
                    output.write('\n' + str(error) + '\n')
                    print(str(error) or 'Build interrupted', file=sys.stderr)
            output.write(f'\nExit code: {code}\nElapsed: {time.monotonic() - start:.2f}s\n')
    except OSError as error:
        print('Unable to execute command:', error, file=sys.stderr)
        return 127
    print(f'{"SUCCESS" if code == 0 else "FAILED"} ({time.monotonic() - start:.1f}s)')
    print('Log:', log)
    if quiet and code != 0 and tail:
        print(f'Last {tail} output lines:', file=sys.stderr)
        for line in recent:
            print(line, file=sys.stderr)
    return code


def main():
    args = cli()
    root = find_root(args.root if args.root else Path(__file__).resolve().parent)
    if root is None:
        print(f'ERROR: {PROJECT_FILE} not found. Use --root PATH.', file=sys.stderr)
        return 2
    if args.command == 'doctor':
        return diagnose(root, args.target)
    if not args.dry_run and not shutil.which('haxelib'):
        print('ERROR: haxelib is not installed or not in PATH.', file=sys.stderr)
        return 127
    logdir = args.log_dir if args.log_dir.is_absolute() else root / args.log_dir
    stamp = now()
    if args.clean_first:
        clean_log = logdir / f'clean_{args.target}_{stamp}.log'
        result = run(lime_command(args, 'clean'), root, clean_log, args.quiet,
                     args.dry_run, args.timeout, args.tail)
        if result:
            return result
    logfile = logdir / f'{args.command}_{args.target}_{args.mode}_{stamp}.log'
    return run(lime_command(args, args.command), root, logfile, args.quiet,
               args.dry_run, args.timeout, args.tail)


if __name__ == '__main__':
    sys.exit(main())
