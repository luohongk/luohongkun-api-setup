import pathlib
import json
import os
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]


class ConfigDirTests(unittest.TestCase):
    def test_codex_ps1_prefers_codex_home(self) -> None:
        content = (REPO_ROOT / "codex.ps1").read_text(encoding="utf-8")

        self.assertIn('$ConfigDir = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME))', content)
        self.assertIn('$env:CODEX_HOME', content)
        self.assertIn('Join-Path $HOME ".codex"', content)

    def test_codex_sh_prefers_codex_home(self) -> None:
        content = (REPO_ROOT / "codex.sh").read_text(encoding="utf-8")

        self.assertIn('CONFIG_DIR="${CODEX_HOME:-$HOME/.codex}"', content)

    def test_claude_ps1_prefers_claude_config_dir(self) -> None:
        content = (REPO_ROOT / "claude.ps1").read_text(encoding="utf-8")

        self.assertIn('$SettingsDir = if ([string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR))', content)
        self.assertIn('$env:CLAUDE_CONFIG_DIR', content)
        self.assertIn('Join-Path $HOME ".claude"', content)

    def test_claude_sh_prefers_claude_config_dir(self) -> None:
        content = (REPO_ROOT / "claude.sh").read_text(encoding="utf-8")

        self.assertIn('SETTINGS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"', content)

    def test_readme_documents_environment_overrides(self) -> None:
        content = (REPO_ROOT / "README.md").read_text(encoding="utf-8")

        self.assertIn("`CODEX_HOME`", content)
        self.assertIn("`CLAUDE_CONFIG_DIR`", content)

    def test_shell_scripts_use_lf_line_endings(self) -> None:
        for name in ("claude.sh", "codex.sh"):
            with self.subTest(name=name):
                content = (REPO_ROOT / name).read_bytes()
                self.assertNotIn(b"\r\n", content)

    def test_gitattributes_enforces_lf_for_shell_scripts(self) -> None:
        content = (REPO_ROOT / ".gitattributes").read_text(encoding="utf-8")

        self.assertIn("*.sh text eol=lf", content)

    def test_claude_ps1_preserves_existing_env_on_windows_powershell(self) -> None:
        temp_dir = tempfile.mkdtemp(prefix="provider-setup-claude-")
        self.addCleanup(lambda: shutil.rmtree(temp_dir, ignore_errors=True))

        settings_file = pathlib.Path(temp_dir) / "settings.json"
        settings_file.write_text(
            json.dumps({"env": {"EXISTING": "1"}}, ensure_ascii=False),
            encoding="utf-8",
        )

        env = os.environ.copy()
        env["CLAUDE_CONFIG_DIR"] = temp_dir

        completed = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(REPO_ROOT / "claude.ps1"),
                "-ApiKey",
                "test-key",
            ],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(
            completed.returncode,
            0,
            msg=f"stdout:\n{completed.stdout}\n\nstderr:\n{completed.stderr}",
        )

        data = json.loads(settings_file.read_text(encoding="utf-8-sig"))
        self.assertEqual(data["env"]["EXISTING"], "1")
        self.assertEqual(data["env"]["ANTHROPIC_AUTH_TOKEN"], "test-key")

    def test_codex_ps1_writes_model_provider_at_top_level(self) -> None:
        temp_dir = tempfile.mkdtemp(prefix="provider-setup-codex-")
        self.addCleanup(lambda: shutil.rmtree(temp_dir, ignore_errors=True))

        config_file = pathlib.Path(temp_dir) / "config.toml"
        config_file.write_text(
            "\n".join(
                [
                    "# existing comment",
                    "",
                    "[projects.'E:\\\\github\\\\demo']",
                    'trust_level = "trusted"',
                    "",
                ]
            ),
            encoding="utf-8",
        )

        env = os.environ.copy()
        env["CODEX_HOME"] = temp_dir

        completed = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(REPO_ROOT / "codex.ps1"),
                "-ApiKey",
                "test-key",
            ],
            cwd=REPO_ROOT,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertEqual(
            completed.returncode,
            0,
            msg=f"stdout:\n{completed.stdout}\n\nstderr:\n{completed.stderr}",
        )

        content = config_file.read_text(encoding="utf-8-sig")
        lines = content.splitlines()
        non_empty_lines = [line for line in lines if line.strip()]

        self.assertGreaterEqual(len(non_empty_lines), 4, content)
        self.assertEqual(non_empty_lines[0], "# existing comment")
        self.assertEqual(non_empty_lines[1], 'model_provider = "xixu"')
        self.assertEqual(non_empty_lines[2], "[projects.'E:\\\\github\\\\demo']")
        self.assertIn("[model_providers.xixu]", non_empty_lines)


if __name__ == "__main__":
    unittest.main()
