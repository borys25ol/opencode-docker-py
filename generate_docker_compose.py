import shutil
from datetime import datetime
from pathlib import Path

import typer


def backup_existing_file(filepath: Path, backup_dir: Path) -> Path | None:
    """Backup an existing file to a specified backup directory."""
    if not filepath.exists():
        return None

    backup_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_filename = f"{filepath.name}.backup_{timestamp}"
    backup_path = backup_dir / backup_filename

    shutil.copy2(filepath, backup_path)
    return backup_path


def generate_docker_compose_yaml(masked_dirs: list[str]) -> str:
    """Generate a docker-compose.yml file based on masked directories."""
    masked_volumes_yaml = "\n".join([f"      - /workspace/{d}" for d in masked_dirs])

    yaml_content = f"""services:
  agent:
    build:
      context: .
      dockerfile: ./docker/Dockerfile
    container_name: opencode-docker-py-agent
    ports:
      # For running OpenCode in UI mode.
      - "4096:4096"
      # For running local API server, FastAPI as an example.
      - "8080:8080"
    volumes:
      # Config files mounted to /home/opencode/.config/opencode.
      - ./config/AGENT_RULES.md:/home/opencode/.config/opencode/AGENT_RULES.md:ro
      - ./config/opencode.json:/home/opencode/.config/opencode/opencode.json:ro

      # Project directory mounted to /workspace.
      - ${{HOST_DIR}}:/workspace

      # Masking {", ".join(masked_dirs)} to prevent it from being mounted.
{masked_volumes_yaml}

      # UV cache
      - uv_cache:/home/opencode/.cache/uv
    env_file:
      - .env
    tty: true
    stdin_open: true

volumes:
  uv_cache:
    # Dynamic volume name in Docker for uv cache.
    name: ${{PROJECT_NAME}}_uv_cache
"""
    return yaml_content


def main(
    masked_dirs: str = typer.Option(
        ".venv .ve .git",
        "--masked-dirs",
        "-m",
        help="Space-separated directories to mask",
    ),
    output: str = typer.Option(
        "docker-compose.yml", "--output", "-o", help="Output file path"
    ),
    backup_dir: str = typer.Option(
        "backups", "--backup-dir", "-b", help="Backup directory path"
    ),
) -> None:
    output_path: Path = Path(output)
    backup_path: Path = Path(backup_dir)

    masked_list: list[str] = masked_dirs.split()

    backup: Path | None = backup_existing_file(
        filepath=output_path, backup_dir=backup_path
    )
    if backup:
        typer.echo(f"Backed up existing file to: {backup}")

    yaml_content: str = generate_docker_compose_yaml(masked_dirs=masked_list)

    with open(output_path, "w") as f:
        f.write(yaml_content)

    typer.echo(f"Generated docker-compose file: {output_path}")


if __name__ == "__main__":
    typer.run(main)
