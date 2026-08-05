

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Lua Obfuscator Discord Bot  —  v3.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 1 : custom obfuscator
  • Visually-confusing name mangling  (lIiOo0 charset)
  • string.char() encoding
  • XOR string encoding (runtime decoder)
  • Number split-expression encoding
  • Dead-code / junk injection
  • Full minification

Layer 2 : WeAreDevs Prometheus  (optional, !toggle prometheus on)
  • Sends layer-1 output to wearedevs.net/api/obfuscate
  • Prometheus applies VM-level obfuscation on top
  • Combined result is extremely hard to reverse-engineer

Commands:
  !obfuscate <lua code | raw url>   (or attach .lua file)
  !config
  !setlevel 0-100
  !toggle mangle|strings|numbers|minify|junk|xor|prometheus on|off
  !reset
  !helpobf
  !ping
"""

import asyncio
import io
import json
import os
import random
import re
from dataclasses import dataclass, asdict
from pathlib import Path
from urllib.parse import urlparse

import discord
import requests
from discord.ext import commands

# ────────────────────────────────────────────────────────────────────────────────
#  Constants
# ────────────────────────────────────────────────────────────────────────────────

BOT_TOKEN   = os.getenv("DISCORD_TOKEN", "token herw").strip()
PREFIX      = "!"
CONFIG_DIR  = Path("./obfuscator_configs")
CONFIG_DIR.mkdir(parents=True, exist_ok=True)

DEFAULT_LEVEL      = 60
DISCORD_TEXT_LIMIT = 1900
FETCH_TIMEOUT      = 15
PROMETHEUS_URL     = "https://wearedevs.net/api/obfuscate"
PROMETHEUS_TIMEOUT = 30   # their server can be slow

LUA_KEYWORDS = {
    "and","break","do","else","elseif","end","false","for","function",
    "goto","if","in","local","nil","not","or","repeat","return",
    "then","true","until","while",
}

LUA_GLOBALS = {
    # Lua stdlib
    "_G","_ENV","_VERSION",
    "assert","collectgarbage","dofile","error","getmetatable","ipairs",
    "load","loadfile","next","pairs","pcall","print","rawequal",
    "rawget","rawlen","rawset","require","select","setmetatable",
    "tonumber","tostring","type","warn","xpcall",
    "coroutine","debug","io","math","os","package","string","table","utf8","bit32",
    # Roblox globals
    "game","workspace","script","plugin",
    "Instance","Vector3","Vector2","CFrame","Color3","BrickColor",
    "UDim2","UDim","Rect","Region3","NumberSequence","ColorSequence",
    "NumberRange","Axes","Faces","Ray","Enum","RaycastParams",
    "task","tick","time","wait","spawn","delay","coroutine",
    "getfenv","setfenv","loadstring",
    # Executor globals (Delta / Synapse etc.)
    "getgenv","gethui","syn","setsimulationradius",
    "fireproximityprompt","hookfunction","newcclosure","iscclosure",
    "checkcaller","cloneref","getreg","getconnections","getsenv",
    "getrawmetatable","setrawmetatable","getnamecallmethod",
    "isreadonly","makereadonly","iswriteable",
    "firetouchinterest","fireproximityprompt",
    "InputHoldBegin","InputHoldEnd",
    # Services commonly referenced bare
    "RunService","Players","UserInputService","ReplicatedStorage",
    "TweenService","PathfindingService","HttpService","StarterGui",
    "SoundService","Lighting","MarketplaceService","VirtualUser",
}

RAW_HOSTS = {
    "raw.githubusercontent.com",
    "gist.githubusercontent.com",
    "githubusercontent.com",
    "pastebin.com",
}

GITHUB_BLOB_RE = re.compile(
    r"^https?://github\.com/(?P<u>[^/]+)/(?P<r>[^/]+)/blob/(?P<b>[^/]+)/(?P<p>.+)$", re.I)
GIST_RE        = re.compile(
    r"^https?://gist\.github\.com/(?P<u>[^/]+)/(?P<g>[0-9a-fA-F]+)$", re.I)
PASTEBIN_RE    = re.compile(
    r"^https?://pastebin\.com/(?!raw/)(?P<id>[A-Za-z0-9]+)$", re.I)


# ────────────────────────────────────────────────────────────────────────────────
#  UserConfig
# ────────────────────────────────────────────────────────────────────────────────

@dataclass
class UserConfig:
    user_id          : int
    mangle_names     : bool = True
    encode_strings   : bool = True
    encode_numbers   : bool = False
    minify           : bool = True
    protection_level : int  = DEFAULT_LEVEL
    preserve_globals : bool = True
    inject_junk      : bool = False
    xor_strings      : bool = False
    use_prometheus   : bool = False   # ← WeAreDevs layer

    def to_dict(self):
        return asdict(self)

    @classmethod
    def from_dict(cls, data):
        defaults = {
            "user_id": 0, "mangle_names": True, "encode_strings": True,
            "encode_numbers": False, "minify": True,
            "protection_level": DEFAULT_LEVEL, "preserve_globals": True,
            "inject_junk": False, "xor_strings": False, "use_prometheus": False,
        }
        if isinstance(data, dict):
            defaults.update({k: v for k, v in data.items() if k in defaults})
        return cls(**defaults)

    def apply_protection_level(self):
        lvl = max(0, min(100, int(self.protection_level)))
        self.protection_level = lvl
        if lvl <= 24:
            self.minify=True; self.mangle_names=False
            self.encode_strings=False; self.encode_numbers=False
            self.inject_junk=False; self.xor_strings=False
        elif lvl <= 49:
            self.minify=True; self.mangle_names=True
            self.encode_strings=False; self.encode_numbers=False
            self.inject_junk=False; self.xor_strings=False
        elif lvl <= 74:
            self.minify=True; self.mangle_names=True
            self.encode_strings=True; self.encode_numbers=False
            self.inject_junk=False; self.xor_strings=False
        elif lvl <= 89:
            self.minify=True; self.mangle_names=True
            self.encode_strings=True; self.encode_numbers=True
            self.inject_junk=False; self.xor_strings=False
        else:
            self.minify=True; self.mangle_names=True
            self.encode_strings=True; self.encode_numbers=True
            self.inject_junk=True; self.xor_strings=True


class ConfigManager:
    def __init__(self):
        self.cache = {}

    def _path(self, uid): return CONFIG_DIR / f"{uid}.json"

    def load(self, uid):
        if uid in self.cache: return self.cache[uid]
        p = self._path(uid)
        try:
            cfg = UserConfig.from_dict(json.loads(p.read_text("utf-8"))) if p.exists() else UserConfig(user_id=uid)
        except Exception:
            cfg = UserConfig(user_id=uid)
        cfg.apply_protection_level()
        self.cache[uid] = cfg
        return cfg

    def save(self, cfg):
        cfg.apply_protection_level()
        self.cache[cfg.user_id] = cfg
        self._path(cfg.user_id).write_text(json.dumps(cfg.to_dict(), indent=2), "utf-8")

    def reset(self, uid):
        cfg = UserConfig(user_id=uid)
        cfg.apply_protection_level()
        self.save(cfg)
        return cfg


config_manager = ConfigManager()


# ────────────────────────────────────────────────────────────────────────────────
#  Tokenizer
# ────────────────────────────────────────────────────────────────────────────────

class Token:
    __slots__ = ("kind","value","start","end")
    def __init__(self, k, v, s, e):
        self.kind=k; self.value=v; self.start=s; self.end=e


_NUM_RE = re.compile(
    r"0[xX][0-9A-Fa-f]+(?:\.[0-9A-Fa-f]*)?(?:[pP][+-]?\d+)?"
    r"|\d+(?:\.\d*)?(?:[eE][+-]?\d+)?"
    r"|\.\d+(?:[eE][+-]?\d+)?",
)

def _is_id_start(c): return c == "_" or c.isalpha()
def _is_id_part(c):  return c == "_" or c.isalnum()

def _long_bracket(src, i):
    if i >= len(src) or src[i] != "[": return None
    j = i+1; eq = 0
    while j < len(src) and src[j] == "=": eq += 1; j += 1
    return (eq, j+1) if j < len(src) and src[j] == "[" else None

def _long_end(src, start, eq):
    c = "]" + "="*eq + "]"
    p = src.find(c, start)
    return len(src) if p == -1 else p + len(c)


def scan_lua(src):
    tokens, i, n = [], 0, len(src)
    while i < n:
        ch = src[i]
        # whitespace
        if ch.isspace():
            j = i+1
            while j < n and src[j].isspace(): j += 1
            tokens.append(Token("ws", src[i:j], i, j)); i = j; continue
        # comments
        if ch == "-" and i+1 < n and src[i+1] == "-":
            lb = _long_bracket(src, i+2)
            if lb:
                eq, start = lb; end = _long_end(src, start, eq)
                tokens.append(Token("comment", src[i:end], i, end)); i = end; continue
            j = i+2
            while j < n and src[j] != "\n": j += 1
            tokens.append(Token("comment", src[i:j], i, j)); i = j; continue
        # short strings
        if ch in ("'", '"'):
            q = ch; j = i+1; esc = False
            while j < n:
                c = src[j]
                if esc: esc = False
                elif c == "\\": esc = True
                elif c == q: j += 1; break
                j += 1
            tokens.append(Token("string", src[i:j], i, j)); i = j; continue
        # long strings
        lb = _long_bracket(src, i)
        if lb:
            eq, start = lb; end = _long_end(src, start, eq)
            tokens.append(Token("string", src[i:end], i, end)); i = end; continue
        # identifiers
        if _is_id_start(ch):
            j = i+1
            while j < n and _is_id_part(src[j]): j += 1
            tokens.append(Token("ident", src[i:j], i, j)); i = j; continue
        # numbers
        m = _NUM_RE.match(src, i)
        if m:
            tokens.append(Token("number", m.group(0), i, m.end())); i = m.end(); continue
        # multi-char ops
        for op in ("...","..","==","~=","<=",">=","::","//","<<",">>"):
            if src.startswith(op, i):
                tokens.append(Token("sym", op, i, i+len(op))); i += len(op); break
        else:
            tokens.append(Token("sym", ch, i, i+1)); i += 1
    return tokens


# ────────────────────────────────────────────────────────────────────────────────
#  String decode
# ────────────────────────────────────────────────────────────────────────────────

_ESC = {"a":"\a","b":"\b","f":"\f","n":"\n","r":"\r","t":"\t",
        "v":"\v","\\":"\\",'"':'"',"'":"'","0":"\0"}

def decode_quoted_string(raw):
    if len(raw) < 2 or raw[0] not in ("'",'"') or raw[-1] != raw[0]: return None
    body = raw[1:-1]; out = []; i = 0
    while i < len(body):
        c = body[i]
        if c != "\\":
            out.append(c); i += 1; continue
        if i+1 >= len(body): out.append("\\"); break
        nxt = body[i+1]
        if nxt.isdigit():
            j = i+1; d = []
            while j < len(body) and len(d) < 3 and body[j].isdigit(): d.append(body[j]); j += 1
            try: out.append(chr(int("".join(d))&0xFF)); i = j; continue
            except ValueError: pass
        if nxt in ("x","X") and i+3 < len(body):
            hx = body[i+2:i+4]
            if re.fullmatch(r"[0-9A-Fa-f]{2}", hx): out.append(chr(int(hx,16))); i += 4; continue
        if nxt in ("u","U") and i+2 < len(body) and body[i+2] == "{":
            j = i+3; buf = []
            while j < len(body) and body[j] != "}": buf.append(body[j]); j += 1
            if j < len(body) and re.fullmatch(r"[0-9A-Fa-f]+","".join(buf)):
                out.append(chr(int("".join(buf),16))); i = j+1; continue
        if nxt == "z":
            j = i+2
            while j < len(body) and body[j].isspace(): j += 1
            i = j; continue
        r = _ESC.get(nxt)
        if r is not None: out.append(r); i += 2; continue
        out.append(nxt); i += 2
    return "".join(out)


def decode_string_token(raw):
    if raw.startswith(("'",'"')): return decode_quoted_string(raw)
    if raw.startswith("["):
        m = re.match(r"^\[(=*)\[(.*)\]\1\]$", raw, re.S)
        if m: return m.group(2)
    return None


# ────────────────────────────────────────────────────────────────────────────────
#  Encoding helpers
# ────────────────────────────────────────────────────────────────────────────────

def _char_expr(text):
    if not text: return '""'
    parts = [str(ord(c)) for c in text]
    if len(parts) <= 16: return "string.char("+",".join(parts)+")"
    chunks = ["string.char("+",".join(parts[i:i+16])+")" for i in range(0,len(parts),16)]
    return "("+("..").join(chunks)+")"


def _xor_expr(text, rnd):
    """XOR encode with a random key, emit a table-based runtime decoder."""
    if not text: return '""'
    key   = rnd.randint(1, 127)
    xored = [ord(c)^key for c in text]
    tbl   = "{"+",".join(str(b) for b in xored)+"}"
    # two random temp names to avoid collisions
    vt = "_"+"".join(rnd.choice("abcdef") for _ in range(4))
    vi = "_"+"".join(rnd.choice("abcdef") for _ in range(4))
    vv = "_"+"".join(rnd.choice("abcdef") for _ in range(4))
    return (
        f"(function()"
        f"local {vt}={{}}"
        f"for {vi},{vv} in ipairs({tbl})do"
        f" {vt}[{vi}]=string.char({vv}~{key})"
        f" end"
        f" return table.concat({vt})"
        f" end)()"
    )


def _base64_expr(text, rnd):
    """Encode via base64 table lookup + runtime decoder — a 3rd encoding style."""
    if not text or len(text) > 120: return _char_expr(text)  # fallback for long strings
    import base64
    b64 = base64.b64encode(text.encode()).decode()
    vd = "_"+"".join(rnd.choice("abcdef") for _ in range(4))
    vr = "_"+"".join(rnd.choice("abcdef") for _ in range(4))
    vi = "_"+"".join(rnd.choice("abcdef") for _ in range(4))
    # Inline base64 decoder in Lua
    return (
        f'(function()'
        f'local {vd}="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"'
        f' local {vr}=""'
        f' local {vi}=0'
        f' local b,c,p,q,r,s'
        f' for x in string.gmatch("{b64}",".")do'
        f' {vi}={vi}*64+(string.find({vd},x,1,true)-1)'
        f' if #{vr}*6%24==18 then'
        f' {vr}={vr}..string.char(({vi}>>16)&255,({vi}>>8)&255,{vi}&255)'
        f' {vi}=0'
        f' end end'
        f' return {vr}'
        f' end)()'
    )


def encode_str(text, rnd, xor=False):
    if not text: return '""'
    pick = rnd.random()
    if xor:
        if pick < 0.45: return _xor_expr(text, rnd)
        if pick < 0.70: return _char_expr(text)
        return _base64_expr(text, rnd)
    return _char_expr(text)


def _int_expr(v, rnd):
    if v == 0:  return "(1-1)"
    if v == 1:  return "(2-1)"
    if v == -1: return "(0-1)"
    parts = rnd.randint(2, 4); rem = v; terms = []
    for k in range(parts-1):
        span = max(1, abs(rem)//max(2, parts-k))
        p = rnd.randint(-span, span); terms.append(p); rem -= p
    terms.append(rem)
    expr = str(terms[0])
    for t in terms[1:]:
        expr = f"({expr}+{t})" if t >= 0 else f"({expr}{t})"
    if rnd.random() < 0.6:  expr = f"(({expr})+0)"
    if rnd.random() < 0.35: expr = f"(({expr})*1)"
    return expr


def encode_num(text, rnd):
    if re.fullmatch(r"[+-]?\d+", text):
        try: return _int_expr(int(text,10), rnd)
        except: pass
    return f"(({text})+0)"


# ────────────────────────────────────────────────────────────────────────────────
#  Junk / dead-code generators
# ────────────────────────────────────────────────────────────────────────────────

def _gen_junk(rnd, pool):
    """Dead `if false then ... end` block."""
    n  = rnd.choice(pool) if pool else "_jk"
    v  = rnd.choice(["nil","true","false",f"{rnd.randint(0,9999)}"])
    c  = rnd.choice(["false","(1==2)","(0~=0)","(type(nil)=='number')"])
    return f"if {c} then local {n}={v} end "


def _gen_fake_branch(rnd, pool):
    """A slightly more complex dead branch with nested ops."""
    n1 = rnd.choice(pool) if pool else "_fa"
    n2 = rnd.choice(pool) if pool else "_fb"
    ops = [f"local {n1}=0 local {n2}={n1}+1",
           f"local {n1}=math.abs(-1)",
           f"local {n1}=string.len(\"\")"]
    return f"if false then {rnd.choice(ops)} end "


# ────────────────────────────────────────────────────────────────────────────────
#  Obfuscator
# ────────────────────────────────────────────────────────────────────────────────

class LuaObfuscator:
    CHARSET = "lIiOo0"   # visually indistinguishable names

    def __init__(self, cfg: UserConfig):
        self.cfg   = cfg
        self.rnd   = random.Random()
        self.stack : list[dict] = []
        self.used  : set        = set()
        self.ctr   = 0

    # ── name generation ──────────────────────────────────────────────────────

    def new_name(self):
        while True:
            self.ctr += 1
            length = 7 + (self.ctr % 7)
            name = "".join(self.rnd.choice(self.CHARSET) for _ in range(length))
            if name[0].isdigit(): name = "l" + name[1:]
            if name not in self.used and name not in LUA_KEYWORDS and name not in LUA_GLOBALS:
                self.used.add(name); return name

    def _pool(self, n=10): return [self.new_name() for _ in range(n)]

    # ── scope ────────────────────────────────────────────────────────────────

    def push(self): self.stack.append({})
    def pop(self):
        if self.stack: self.stack.pop()

    def declare(self, name):
        if not self.stack: self.push()
        if name in LUA_KEYWORDS: return name
        if self.cfg.preserve_globals and name in LUA_GLOBALS: return name
        if name.startswith("__"): return name
        s = self.stack[-1]
        if name not in s: s[name] = self.new_name()
        return s[name]

    def lookup(self, name):
        for s in reversed(self.stack):
            if name in s: return s[name]
        return None

    def collect_scopes(self, tokens):
        self.stack = []; self.push()
        i = 0; n = len(tokens)
        while i < n:
            t = tokens[i]

            # function → new scope + param declaration
            if t.kind == "ident" and t.value == "function":
                self.push(); i += 1
                while i < n and not (tokens[i].kind=="sym" and tokens[i].value=="("): i += 1
                if i < n:
                    i += 1
                    while i < n:
                        tt = tokens[i]
                        if tt.kind=="sym" and tt.value==")": i += 1; break
                        if tt.kind=="ident" and tt.value != "...": self.declare(tt.value)
                        i += 1
                continue

            # local  [function]  name
            if t.kind == "ident" and t.value == "local":
                j = i+1
                while j < n and tokens[j].kind=="ws": j += 1
                if j < n and tokens[j].kind=="ident" and tokens[j].value=="function":
                    j += 1
                    while j < n and tokens[j].kind=="ws": j += 1
                    if j < n and tokens[j].kind=="ident": self.declare(tokens[j].value); j += 1
                    i = j; continue
                # local a, b, c
                while j < n:
                    while j < n and tokens[j].kind=="ws": j += 1
                    if j >= n: break
                    tt = tokens[j]
                    if tt.kind=="ident" and tt.value not in LUA_KEYWORDS:
                        self.declare(tt.value); j += 1
                        while j < n and tokens[j].kind=="ws": j += 1
                        if j < n and tokens[j].kind=="sym" and tokens[j].value==",": j += 1; continue
                        break
                    else: break
                i = j; continue

            # for i / for k,v  — FIX: properly advance i
            if t.kind == "ident" and t.value == "for":
                j = i+1; vf = []
                while j < n:
                    tt = tokens[j]
                    if tt.kind=="ws": j += 1; continue
                    if tt.kind=="ident" and tt.value in ("in","do"): break
                    if tt.kind=="sym" and tt.value=="=": break
                    if tt.kind=="ident": vf.append(tt.value)
                    j += 1
                for nm in vf: self.declare(nm)
                i = j+1; continue

            if t.kind=="ident" and t.value in ("do","then","repeat"): self.push()
            elif t.kind=="ident" and t.value in ("end","until"): self.pop()
            i += 1

    # ── emit ─────────────────────────────────────────────────────────────────

    def _compact(self, s):
        s = re.sub(r"[ \t]+"," ", s)
        s = re.sub(r"\s*([=+\-*/%<>~:,;(){}\[\]])\s*", r"\1", s)
        s = re.sub(r"\s*\.\.\s*", "..", s)
        s = re.sub(r"\s+"," ", s)
        return s.strip()

    def emit(self, tokens):
        cfg = self.cfg
        out = []
        jpool    = self._pool(14) if cfg.inject_junk else []
        jcounter = 0

        def ap(text):
            if not text: return
            if out:
                l, f = out[-1][-1], text[0]
                if (l.isalnum() or l=="_") and (f.isalnum() or f=="_"): out.append(" ")
            out.append(text)

        for t in tokens:
            if t.kind in ("ws","comment"):
                if not cfg.minify and out and not out[-1].endswith((" ","\n")): out.append(" ")
                continue

            # junk injection after certain keywords
            if cfg.inject_junk and t.kind=="ident" and t.value in ("end","then","do"):
                jcounter += 1
                if jcounter % 2 == 0:
                    ap(_gen_junk(self.rnd, jpool))
                elif jcounter % 5 == 0:
                    ap(_gen_fake_branch(self.rnd, jpool))

            if t.kind=="ident":
                if cfg.mangle_names and t.value not in LUA_KEYWORDS and \
                   not (cfg.preserve_globals and t.value in LUA_GLOBALS):
                    ap(self.lookup(t.value) or t.value)
                else:
                    ap(t.value)
                continue

            if t.kind=="string" and cfg.encode_strings:
                dec = decode_string_token(t.value)
                ap(encode_str(dec, self.rnd, xor=cfg.xor_strings) if dec is not None else t.value)
                continue

            if t.kind=="number" and cfg.encode_numbers:
                ap(encode_num(t.value, self.rnd)); continue

            ap(t.value)

        result = "".join(out)
        if cfg.minify: result = self._compact(result)
        return result

    # ── public ───────────────────────────────────────────────────────────────

    def obfuscate(self, code: str):
        cfg = UserConfig.from_dict(self.cfg.to_dict())
        cfg.apply_protection_level()
        self.cfg = cfg

        tokens = scan_lua(code)
        self.rnd.seed(random.randint(1, 10**9))
        self.used.clear(); self.ctr = 0; self.stack = []

        if cfg.mangle_names: self.collect_scopes(tokens)

        result = self.emit(tokens)
        stats = {
            "orig"     : len(code),
            "obf"      : len(result),
            "pct"      : round((1 - len(result)/max(len(code),1))*100, 1),
            "level"    : cfg.protection_level,
            "strings"  : sum(1 for t in tokens if t.kind=="string"),
            "numbers"  : sum(1 for t in tokens if t.kind=="number"),
            "comments" : sum(1 for t in tokens if t.kind=="comment"),
        }
        return result, stats


# ────────────────────────────────────────────────────────────────────────────────
#  WeAreDevs Prometheus wrapper
# ────────────────────────────────────────────────────────────────────────────────

def prometheus_obfuscate(code: str) -> str:
    """
    Call wearedevs.net/api/obfuscate (Prometheus backend).
    Returns obfuscated string or raises RuntimeError.
    """
    try:
        resp = requests.post(
            PROMETHEUS_URL,
            json={"script": code},
            headers={
                "Content-Type": "application/json",
                "User-Agent"  : "Mozilla/5.0 (LuaObfBot/3.0)",
                "Origin"      : "https://wearedevs.net",
                "Referer"     : "https://wearedevs.net/obfuscator",
            },
            timeout=PROMETHEUS_TIMEOUT,
        )
        resp.raise_for_status()
        data = resp.json()
        if "error" in data:
            raise RuntimeError(f"Prometheus error: {data['error']}")
        obf = data.get("obfuscated") or data.get("result") or data.get("script")
        if not obf:
            raise RuntimeError("Prometheus returned empty result")
        return obf
    except requests.RequestException as e:
        raise RuntimeError(f"Prometheus unreachable: {e}")


# ────────────────────────────────────────────────────────────────────────────────
#  Misc helpers
# ────────────────────────────────────────────────────────────────────────────────

def strip_fence(text):
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:lua)?\s*","", text, flags=re.I)
        text = re.sub(r"\s*```$","", text)
    return text.strip()


def fmt_cfg(cfg: UserConfig):
    p = "✅" if cfg.use_prometheus else "❌"
    return (
        f"Protection Level : {cfg.protection_level}%\n"
        f"Mangle Names     : {'ON' if cfg.mangle_names   else 'OFF'}\n"
        f"Encode Strings   : {'ON' if cfg.encode_strings else 'OFF'}\n"
        f"XOR Strings      : {'ON' if cfg.xor_strings    else 'OFF'}\n"
        f"Encode Numbers   : {'ON' if cfg.encode_numbers else 'OFF'}\n"
        f"Inject Junk      : {'ON' if cfg.inject_junk    else 'OFF'}\n"
        f"Minify           : {'ON' if cfg.minify         else 'OFF'}\n"
        f"Preserve Globals : {'ON' if cfg.preserve_globals else 'OFF'}\n"
        f"Prometheus Layer : {p} {'ON (double-obf via WeAreDevs)' if cfg.use_prometheus else 'OFF'}"
    )


def is_url(text):
    try:
        p = urlparse(text.strip())
        return p.scheme in ("http","https") and bool(p.netloc)
    except: return False


def normalize_url(url):
    url = url.strip()
    m = GITHUB_BLOB_RE.match(url)
    if m: return f"https://raw.githubusercontent.com/{m.group('u')}/{m.group('r')}/{m.group('b')}/{m.group('p')}"
    m = GIST_RE.match(url)
    if m: return f"https://gist.githubusercontent.com/{m.group('u')}/{m.group('g')}/raw"
    m = PASTEBIN_RE.match(url)
    if m: return f"https://pastebin.com/raw/{m.group('id')}"
    return url


def url_allowed(url):
    host = (urlparse(url).netloc or "").lower()
    return host in RAW_HOSTS or host.endswith(".raw.githubusercontent.com")


def fetch_url(url):
    url = normalize_url(url)
    if not is_url(url): raise ValueError("Not a valid URL.")
    if not url_allowed(url): raise ValueError("Only GitHub raw / Gist / Pastebin raw URLs are allowed.")
    r = requests.get(url, headers={"User-Agent":"LuaObfBot/3.0"}, timeout=FETCH_TIMEOUT, allow_redirects=True)
    r.raise_for_status()
    if "\x00" in r.text[:2000]: raise ValueError("URL does not look like raw text.")
    return r.text


async def get_source(ctx, args):
    if ctx.message.attachments:
        try:
            raw = await ctx.message.attachments[0].read()
            return raw.decode("utf-8","replace"), ctx.message.attachments[0].filename or "script.lua"
        except Exception as e: raise RuntimeError(f"Could not read attachment: {e}")
    text = strip_fence(args)
    if not text: return "", "script.lua"
    if is_url(text):
        try: return await asyncio.to_thread(fetch_url, text), "fetched.lua"
        except Exception as e: raise RuntimeError(str(e))
    return text, "script.lua"


# ────────────────────────────────────────────────────────────────────────────────
#  Bot
# ────────────────────────────────────────────────────────────────────────────────

intents = discord.Intents.default()
intents.message_content = True
intents.guilds = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents, help_command=None)


@bot.event
async def on_ready():
    print(f"[+] {bot.user}  (ID {bot.user.id})  ready.")


# ── !helpobf ────────────────────────────────────────────────────────────────────

@bot.command("helpobf")
async def helpobf(ctx):
    await ctx.reply(
        "**🔒 Lua Obfuscator Bot v3**\n\n"
        "**Obfuscate:**\n"
        "`!obfuscate <code>` — inline Lua\n"
        "`!obfuscate` + attach `.lua` file\n"
        "`!obfuscate <url>` — GitHub raw / Gist / Pastebin\n\n"
        "**Settings:**\n"
        "`!setlevel 0-100` — protection preset (100 = max)\n"
        "`!toggle <feature> on|off`\n"
        "   features: `mangle strings xor numbers junk minify globals prometheus`\n"
        "`!config` — current settings\n"
        "`!reset` — restore defaults\n\n"
        "**Prometheus mode** (`!toggle prometheus on`):\n"
        "Adds a **2nd obfuscation layer** using WeAreDevs/Prometheus on top.\n"
        "Result is extremely hard to reverse-engineer.",
        mention_author=False,
    )


# ── !config ─────────────────────────────────────────────────────────────────────

@bot.command("config")
async def config_cmd(ctx):
    cfg = config_manager.load(ctx.author.id)
    await ctx.reply("```\n" + fmt_cfg(cfg) + "\n```", mention_author=False)


# ── !setlevel ───────────────────────────────────────────────────────────────────

@bot.command("setlevel")
async def setlevel_cmd(ctx, level: int):
    cfg = config_manager.load(ctx.author.id)
    cfg.protection_level = max(0, min(100, level))
    cfg.apply_protection_level()
    config_manager.save(cfg)
    await ctx.reply("Updated:\n```\n" + fmt_cfg(cfg) + "\n```", mention_author=False)


# ── !toggle ─────────────────────────────────────────────────────────────────────

TOGGLE_MAP = {
    "mangle":"mangle_names","names":"mangle_names","mangle_names":"mangle_names",
    "strings":"encode_strings","encode_strings":"encode_strings",
    "numbers":"encode_numbers","encode_numbers":"encode_numbers",
    "minify":"minify",
    "junk":"inject_junk","inject_junk":"inject_junk",
    "xor":"xor_strings","xor_strings":"xor_strings",
    "globals":"preserve_globals","preserve_globals":"preserve_globals",
    "prometheus":"use_prometheus","prom":"use_prometheus",
}

@bot.command("toggle")
async def toggle_cmd(ctx, feature: str, state: str):
    cfg = config_manager.load(ctx.author.id)
    attr = TOGGLE_MAP.get(feature.lower().strip())
    if not attr:
        await ctx.reply(
            "Unknown feature. Options: `mangle strings xor numbers junk minify globals prometheus`",
            mention_author=False); return
    enabled = state.lower().strip() in ("on","true","1","yes","enable","enabled")
    setattr(cfg, attr, enabled)
    config_manager.save(cfg)
    await ctx.reply("```\n" + fmt_cfg(cfg) + "\n```", mention_author=False)


# ── !reset ──────────────────────────────────────────────────────────────────────

@bot.command("reset")
async def reset_cmd(ctx):
    cfg = config_manager.reset(ctx.author.id)
    await ctx.reply("Reset:\n```\n" + fmt_cfg(cfg) + "\n```", mention_author=False)


# ── !ping ───────────────────────────────────────────────────────────────────────

@bot.command("ping")
async def ping_cmd(ctx):
    await ctx.reply(f"Pong `{round(bot.latency*1000)}ms`", mention_author=False)


# ── !obfuscate ──────────────────────────────────────────────────────────────────

@bot.command("obfuscate")
async def obfuscate_cmd(ctx, *, args=""):
    cfg = config_manager.load(ctx.author.id)
    status_lines = ["⏳ **Layer 1** — running custom obfuscator..."]
    if cfg.use_prometheus:
        status_lines.append("⏳ **Layer 2** — Prometheus (WeAreDevs) queued")

    processing = await ctx.reply("\n".join(status_lines), mention_author=False)

    # ── fetch source ────────────────────────────────────────────────────────
    try:
        source, filename = await get_source(ctx, args)
    except Exception as e:
        await processing.edit(content=f"❌ {e}"); return

    if not source or not source.strip():
        await processing.edit(content="Send Lua code, attach a `.lua` file, or give a raw URL.")
        return
    if len(source.strip()) < 8:
        await processing.edit(content="❌ Input too short."); return

    # ── Layer 1: custom obfuscator ──────────────────────────────────────────
    def layer1():
        return LuaObfuscator(cfg).obfuscate(source)

    try:
        result, stats = await asyncio.to_thread(layer1)
    except Exception as e:
        await processing.edit(content=f"❌ Layer 1 failed: `{e}`"); return

    pct   = stats["pct"]
    arrow = "⬇️" if pct > 0 else "⬆️"

    header = (
        f"**Level {cfg.protection_level}%** | "
        f"Mangle={cfg.mangle_names} Strings={cfg.encode_strings} "
        f"XOR={cfg.xor_strings} Numbers={cfg.encode_numbers} Junk={cfg.inject_junk}\n"
        f"Layer 1 {arrow} **{abs(pct)}%** ({stats['orig']} → {stats['obf']} chars)"
    )

    # ── Layer 2: Prometheus ─────────────────────────────────────────────────
    if cfg.use_prometheus:
        await processing.edit(
            content="\n".join(status_lines[:1]).replace("⏳","✅") +
                    "\n⏳ **Layer 2** — Prometheus (WeAreDevs) running..."
        )
        try:
            result = await asyncio.to_thread(prometheus_obfuscate, result)
            header += f"\n🔐 **Layer 2: Prometheus applied** — final size {len(result)} chars"
        except Exception as e:
            header += f"\n⚠️ Prometheus failed (Layer 1 result kept): `{e}`"

    # ── send ────────────────────────────────────────────────────────────────
    out_name = (filename.rsplit(".",1)[0] if "." in filename else filename) + "_obf.lua"

    if len(result) <= DISCORD_TEXT_LIMIT:
        await processing.edit(content=header + f"\n```lua\n{result}\n```")
    else:
        fp = io.BytesIO(result.encode("utf-8","replace"))
        await processing.edit(content=header + "\n📎 File attached ↓")
        await ctx.reply(file=discord.File(fp, filename=out_name), mention_author=False)


# ────────────────────────────────────────────────────────────────────────────────
#  Entry
# ────────────────────────────────────────────────────────────────────────────────

async def main():
    if BOT_TOKEN in ("YOUR_TOKEN_HERE","token here",""):
        print("ERROR: set DISCORD_TOKEN or fill BOT_TOKEN."); return
    async with bot:
        await bot.start(BOT_TOKEN)


if __name__ == "__main__":
    asyncio.run(main())
PYEOF