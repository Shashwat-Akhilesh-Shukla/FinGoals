#!/usr/bin/env python3
"""FinGoals - Start the backend API server."""
import subprocess
import sys
import os


def main():
    print("")
    print("  FinGoals Financial Command Center")
    print("  ===================================")
    print("  API:  http://localhost:8000")
    print("  Docs: http://localhost:8000/docs")
    print("")

    backend_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend")
    subprocess.run(
        [
            sys.executable, "-m", "uvicorn",
            "main:app",
            "--host", "0.0.0.0",
            "--port", "8000",
            "--reload",
        ],
        cwd=backend_dir,
    )


if __name__ == "__main__":
    main()
