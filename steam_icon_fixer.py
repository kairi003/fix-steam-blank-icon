import os
import threading
import time
import subprocess
import requests
import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
from queue import Queue

# ================= CONFIG =================
MIN_ICON_SIZE = 2048

# ==========================================
# BUSCAR ATALHOS (DESKTOP ONLY)
# ==========================================
def find_steam_shortcuts():
    paths = []

    user = os.path.expanduser("~")

    desktop = os.path.join(user, "Desktop")
    onedrive_desktop = os.path.join(user, "OneDrive", "Desktop")

    locations = [desktop]

    if os.path.exists(onedrive_desktop):
        locations.append(onedrive_desktop)

    for base in locations:
        if not os.path.exists(base):
            continue

        for file in os.listdir(base):
            if file.lower().endswith(".url"):
                full = os.path.join(base, file)

                if is_steam_url(full):
                    paths.append(full)

    return paths


def is_steam_url(file_path):
    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if line.startswith("URL=steam://rungameid/"):
                    return True
    except:
        pass
    return False


# ==========================================
# DOWNLOAD
# ==========================================
def download_file(url, dest):
    try:
        r = requests.get(url, timeout=10)
        if r.status_code == 200:
            with open(dest, "wb") as f:
                f.write(r.content)
            return True
    except:
        pass
    return False


# ==========================================
# PROCESSAR
# ==========================================
def process_file(file_path, log_callback):
    url = ""
    icon_file = ""

    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            if line.startswith("URL="):
                url = line.strip().split("=", 1)[1]
            elif line.startswith("IconFile="):
                icon_file = line.strip().split("=", 1)[1]

    if not url.startswith("steam://rungameid/"):
        return False

    gameid = url.replace("steam://rungameid/", "")

    if not icon_file:
        return False

    icon_name = os.path.basename(icon_file)
    icon_dir = os.path.dirname(icon_file)

    os.makedirs(icon_dir, exist_ok=True)

    if os.path.exists(icon_file):
        try:
            os.remove(icon_file)
        except:
            pass

    icon_url = f"https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/{gameid}/{icon_name}"

    log_callback(f"Baixando: {icon_name}")

    if not download_file(icon_url, icon_file):
        log_callback(f"[ERRO] {icon_name}")
        return False

    if os.path.getsize(icon_file) < MIN_ICON_SIZE:
        os.remove(icon_file)
        log_callback(f"[INVALIDO] {icon_name}")
        return False

    os.utime(file_path, None)

    log_callback(f"[OK] {icon_name}")
    return True


# ==========================================
# RESTART EXPLORER
# ==========================================
def restart_explorer(log_callback):
    log_callback("Reiniciando Explorer...")

    subprocess.call("taskkill /IM explorer.exe /F", shell=True)
    time.sleep(2)

    subprocess.call("ie4uinit.exe -ClearIconCache", shell=True)

    local = os.getenv("LOCALAPPDATA")
    explorer_path = os.path.join(local, "Microsoft\\Windows\\Explorer")

    if os.path.isdir(explorer_path):
        for f in os.listdir(explorer_path):
            if "iconcache" in f.lower():
                try:
                    os.remove(os.path.join(explorer_path, f))
                except:
                    pass

    subprocess.Popen("explorer.exe")


# ==========================================
# GUI
# ==========================================
class App:
    def __init__(self, root):
        self.root = root
        self.root.title("Steam Icon Fixer")
        self.root.geometry("600x420")

        self.queue = Queue()

        frame = ttk.Frame(root, padding=10)
        frame.pack(fill="both", expand=True)

        self.btn_scan = ttk.Button(frame, text="🔍 Escanear Desktop", command=self.scan)
        self.btn_scan.pack(fill="x", pady=5)

        self.btn_fix = ttk.Button(frame, text="🛠 Corrigir Tudo", command=self.fix)
        self.btn_fix.pack(fill="x", pady=5)

        self.progress = ttk.Progressbar(frame)
        self.progress.pack(fill="x", pady=5)

        self.log = scrolledtext.ScrolledText(frame, height=15)
        self.log.pack(fill="both", expand=True)

        self.files = []

        # inicia loop da queue
        self.process_queue()

    # ================= UI THREAD SAFE =================
    def log_msg(self, msg):
        self.queue.put(msg)

    def process_queue(self):
        while not self.queue.empty():
            item = self.queue.get()

            if isinstance(item, tuple) and item[0] == "progress":
                self.progress["value"] = item[1]
            else:
                self.log.insert(tk.END, item + "\n")
                self.log.see(tk.END)

        self.root.after(100, self.process_queue)

    # ================= FUNÇÕES =================
    def scan(self):
        self.log_msg("Escaneando Desktop...")
        self.files = find_steam_shortcuts()
        self.log_msg(f"Encontrados: {len(self.files)} atalhos")

    def fix(self):
        if not self.files:
            messagebox.showwarning("Aviso", "Faça o scan primeiro")
            return

        threading.Thread(target=self.run_fix, daemon=True).start()

    def run_fix(self):
        total = len(self.files)

        self.queue.put(("progress", 0))
        self.progress["maximum"] = total

        alterou = False

        for i, file in enumerate(self.files):
            result = process_file(file, self.log_msg)

            if result:
                alterou = True

            self.queue.put(("progress", i + 1))

        if alterou:
            restart_explorer(self.log_msg)
            self.log_msg("Cache reconstruído!")
        else:
            self.log_msg("Nada para corrigir")

        self.log_msg("Finalizado!")
        messagebox.showinfo("Finalizado", "Processo concluído!")


# ==========================================
# MAIN
# ==========================================
if __name__ == "__main__":
    root = tk.Tk()
    app = App(root)
    root.mainloop()
