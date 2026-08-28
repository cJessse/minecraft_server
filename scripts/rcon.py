#!/usr/bin/env python3
"""
Lightweight, zero-dependency Minecraft RCON Client.
Used for executing console commands like 'save-all flush' directly against the server engine.
"""

import sys
import os
import socket
import struct

RCON_HOST = os.environ.get("RCON_HOST", "127.0.0.1")
RCON_PORT = int(os.environ.get("RCON_PORT", "25575"))
RCON_PASS = os.environ.get("RCON_PASSWORD", "SGItosSaveSecretPass2026!")

def send_rcon(command: str, host: str = RCON_HOST, port: int = RCON_PORT, password: str = RCON_PASS, timeout: int = 5) -> str:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        sock.connect((host, port))

        # 1. Authenticate (Type 3: SERVERDATA_AUTH)
        auth_payload = password.encode("utf-8") + b"\x00\x00"
        auth_pkt = struct.pack("<iii", len(auth_payload) + 8, 1, 3) + auth_payload
        sock.sendall(auth_pkt)

        resp = sock.recv(4096)
        if len(resp) < 12:
            raise ConnectionError("Invalid RCON response during authentication.")
        _, resp_id, _ = struct.unpack("<iii", resp[:12])
        if resp_id == -1:
            raise PermissionError("RCON authentication failed (incorrect password).")

        # 2. Execute Command (Type 2: SERVERDATA_EXECCOMMAND)
        cmd_payload = command.encode("utf-8") + b"\x00\x00"
        cmd_pkt = struct.pack("<iii", len(cmd_payload) + 8, 2, 2) + cmd_payload
        sock.sendall(cmd_pkt)

        resp = sock.recv(4096)
        if len(resp) < 12:
            return ""
        body = resp[12:-2].decode("utf-8", errors="replace").strip()
        return body

if __name__ == "__main__":
    cmd = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "save-all flush"
    try:
        output = send_rcon(cmd)
        if output:
            print(f"[RCON] {output}")
        else:
            print(f"[RCON] Comando '{cmd}' enviado com sucesso.")
    except Exception as e:
        print(f"[RCON ERROR] Falha ao enviar comando '{cmd}': {e}", file=sys.stderr)
        sys.exit(1)
