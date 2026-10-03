"""Regression tests for stable Runner builds, using real Git histories."""
import os
import pathlib
import textwrap
import subprocess
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).with_name('runner-image-changed.sh').resolve()

class RunnerImageChangesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.repo = pathlib.Path(self.tmp.name)
        self.git('init', '-q')
        self.git('config', 'user.email', 'ci-test@example.invalid')
        self.git('config', 'user.name', 'CI test')
        for name in ['packages/app/ui.dart', 'packages/runner/bin/runner.dart', 'packages/shared/lib/engine.dart', 'Dockerfile', '.dockerignore']:
            self.write(name, 'initial\n')
        self.write('packages/app/pubspec.yaml', 'name: app\nversion: 1.0.0+7\n')
        self.write('packages/runner/pubspec.yaml', 'name: runner\nversion: 1.0.0\n')
        self.commit('initial')
        self.git('branch', '-M', 'main')

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.repo, text=True).strip()

    def write(self, name, content):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def commit(self, message):
        self.git('add', '.')
        self.git('commit', '-qm', message)

    def changed(self):
        return subprocess.check_output(['bash', str(SCRIPT)], cwd=self.repo, text=True).strip()

    def published(self, version='1.0.0'):
        self.git('tag', 'runner-image/v' + version)

    def test_bootstrap_builds_once_then_app_releases_do_not_build(self):
        self.assertEqual(self.changed(), 'true')
        self.published()
        self.assertEqual(self.changed(), 'false')
        self.write('packages/app/ui.dart', 'new app\n')
        self.commit('fix: app only')
        self.git('tag', 'v1.0.1')
        self.write('packages/app/pubspec.yaml', 'version: 1.0.2+2\n')
        self.commit('another app release')
        self.git('tag', 'v1.0.2')
        self.assertEqual(self.changed(), 'false')

    def test_runner_and_shared_changes_build(self):
        self.published()
        for name in ['packages/runner/bin/runner.dart', 'packages/shared/lib/engine.dart', 'packages/shared/local_dependencies/plugin/pubspec.yaml']:
            with self.subTest(name=name):
                self.write(name, 'changed\n')
                self.commit('runtime change')
                self.assertEqual(self.changed(), 'true')
                self.published(str(len(self.git('tag').splitlines()) + 1) + '.0.0')
                self.assertEqual(self.changed(), 'false')

    def test_failed_publication_remains_pending_after_app_release(self):
        self.published()
        self.write('packages/shared/lib/engine.dart', 'changed\n')
        self.commit('fix: shared')
        self.git('tag', 'v1.0.1')  # App release exists; image publication failed.
        self.write('packages/app/ui.dart', 'new app\n')
        self.commit('fix: app only')
        self.git('tag', 'v1.0.2')
        self.assertEqual(self.changed(), 'true')
        self.published('1.0.2')
        self.assertEqual(self.changed(), 'false')

    def test_build_inputs_and_deleted_sources_build(self):
        self.published()
        for index, name in enumerate(['Dockerfile', '.dockerignore', '.github/workflows/runner-image.yml', '.github/workflows/ci.yml', 'scripts/runner-image-changed.sh']):
            with self.subTest(name=name):
                self.write(name, 'changed\n')
                self.commit('build input change')
                self.assertEqual(self.changed(), 'true')
                self.published(f'2.0.{index}')
        (self.repo / 'packages/shared/lib/engine.dart').unlink()
        self.commit('delete source')
        self.assertEqual(self.changed(), 'true')

    def workflow_script(self, name):
        # Execute the real workflow shell step, not a rewritten version of it.
        lines = SCRIPT.parent.parent.joinpath('.github/workflows/ci.yml').read_text().splitlines()
        start = lines.index('      - name: ' + name)
        run = next(i for i in range(start + 1, len(lines)) if lines[i] == '        run: |')
        end = run + 1
        while end < len(lines) and (lines[end].startswith('          ') or not lines[end].strip()):
            end += 1
        return textwrap.dedent('\n'.join(lines[run + 1:end]))

    def run_release_step(self, changed):
        remote = tempfile.TemporaryDirectory()
        self.addCleanup(remote.cleanup)
        subprocess.check_call(['git', 'init', '--bare', '-q', remote.name])
        self.git('remote', 'add', 'origin', remote.name)
        output = self.repo / 'release-output'
        env = dict(os.environ, GITHUB_REF='refs/heads/main', GITHUB_OUTPUT=str(output), FORCED_BUMP='patch', RUNNER_CHANGED=changed)
        subprocess.run(['bash', '-c', self.workflow_script('Compute and Bump SemVer')], cwd=self.repo, env=env, check=True, capture_output=True)
        return dict(line.split('=', 1) for line in output.read_text().splitlines())

    def test_app_only_stable_release_bumps_app_and_preserves_runner(self):
        self.published()
        self.git('tag', 'v1.0.0')
        self.write('packages/app/ui.dart', 'app change\n')
        self.commit('fix: app')
        self.assertEqual(self.changed(), 'false')
        outputs = self.run_release_step('false')
        self.assertEqual(outputs['tag'], 'v1.0.1')
        self.assertEqual(outputs['commit'], self.git('rev-parse', 'HEAD'))
        self.assertIn('version: 1.0.1+8', (self.repo / 'packages/app/pubspec.yaml').read_text())
        self.assertIn('version: 1.0.0', (self.repo / 'packages/runner/pubspec.yaml').read_text())
        self.assertEqual(self.changed(), 'false')

    def test_runtime_release_builds_bumped_commit_and_records_publication(self):
        self.published()
        self.git('tag', 'v1.0.0')
        self.write('packages/shared/lib/engine.dart', 'runtime change\n')
        self.commit('fix: runtime')
        outputs = self.run_release_step(self.changed())
        self.assertIn('version: 1.0.1', (self.repo / 'packages/runner/pubspec.yaml').read_text())
        self.assertEqual(self.changed(), 'true')  # Still pending until publish completes.
        env = dict(os.environ, RELEASE_TAG=outputs['tag'])
        subprocess.run(['bash', '-c', self.workflow_script('Record published Runner source')], cwd=self.repo, env=env, check=True, capture_output=True)
        self.assertEqual(self.git('rev-parse', 'runner-image/v1.0.1'), outputs['commit'])
        self.assertEqual(self.changed(), 'false')

    def test_unrelated_documentation_does_not_build(self):
        self.published()
        self.write('docs/readme.md', 'documentation\n')
        self.commit('docs')
        self.assertEqual(self.changed(), 'false')

if __name__ == '__main__':
    unittest.main()
