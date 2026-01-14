from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess
from typing import Optional

app = FastAPI(title="n8n-python-render", version="1.0.0")


class RunRequest(BaseModel):
    command: str
    timeout: Optional[int] = 60


@app.get("/")
def root():
    return {"status": "ok"}


@app.post("/run")
def run(req: RunRequest):
    if not req.command or not req.command.strip():
        raise HTTPException(status_code=400, detail="command is required")

    try:
        completed = subprocess.run(
            req.command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=req.timeout if req.timeout else 60,
            executable="/bin/bash",
        )
        return {
            "command": req.command,
            "returncode": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
    except subprocess.TimeoutExpired as e:
        return {
            "command": req.command,
            "returncode": 124,
            "stdout": e.stdout or "",
            "stderr": (e.stderr or "") + "\nCommand timed out",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
