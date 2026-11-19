#!/usr/bin/env python3
# Ask one configured agent a question and run nix-package layout tools.
# Cursor is Grok 4.7, extra high. Fast and the context window come from the user.
# Tcl drives the MAX window.

import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

TOOLS = (
    "mcp-layers",
    "mcp-cell",
    "mcp-paint",
    "mcp-label",
    "mcp-zoom",
    "mcp-nix",
)

NIX_PACKAGES = ("magic", "ngspice", "gawk", "convert", "magick", "identify")

OPENAI_URLS = {
    "openai": "https://api.openai.com/v1/chat/completions",
    "xai": "https://api.x.ai/v1/chat/completions",
    "groq": "https://api.groq.com/openai/v1/chat/completions",
    "mistral": "https://api.mistral.ai/v1/chat/completions",
    "openrouter": "https://openrouter.ai/api/v1/chat/completions",
    "deepseek": "https://api.deepseek.com/chat/completions",
    "together": "https://api.together.xyz/v1/chat/completions",
    "fireworks": "https://api.fireworks.ai/inference/v1/chat/completions",
    "perplexity": "https://api.perplexity.ai/chat/completions",
}

CURSOR = "https://api.cursor.com"
EFFORT_IDS = ("effort", "reasoning", "reasoning_effort")
EFFORT_WANTS = ("xhigh", "extra-high", "extra_high", "high")

SYSTEM = """You are the assistant inside MAX, the Micro Magic layout editor.
Answer any question in ordinary sentences. Use the reference notes when the question is about MAX, Magic, layout, or flylines.
Draw only when the user asks you to draw, paint, or create geometry. Then use the tools, one shape at a time, so each step appears before the next.

Tools, which are nix packages:
- mcp-layers: no arguments. Returns the technology layer names.
- mcp-cell: cell name. Creates that cell and edits it.
- mcp-paint: layer, x1, y1, x2, y2, and a short note. Paints one rectangle in integer database units.
- mcp-label: layer, text, x, y. Places one label.
- mcp-zoom: x1, y1, x2, y2. Zooms the window to that box.
- mcp-nix: package and args. package is one of magic, ngspice, gawk, convert, magick, identify. Use it for a version or a geometry check. Do not use it to paint.

Use only layer names from the technology list you were given. Do not invent names from another PDK. Do not paint on the flyline layer. A flyline is not mask geometry. Do not write a .max file as text.
If the user did not ask you to draw, do not emit a tool list.
If you cannot call tools yourself and the user asked you to draw, reply with only a JSON array. Each item has "tool" and its arguments, for example {"tool":"mcp-paint","layer":"poly","x1":0,"y1":20,"x2":8,"y2":60,"note":"gate"}. No markdown.
"""


class HttpError(Exception):
    def __init__(self, code, body):
        self.code = code
        self.body = body
        Exception.__init__(self, str(code) + " " + body[:300])


def log(msg):
    print("LOG " + str(msg).replace("\n", " / "), flush=True)


def say(msg):
    print("SAY_BEGIN", flush=True)
    for line in str(msg).split("\n"):
        print("SAY " + line, flush=True)
    print("SAY_END", flush=True)


def fail(msg):
    print("ERR " + str(msg).replace("\n", " / "), flush=True)
    sys.exit(1)


def scrub(text, key):
    if key and text and key in text:
        return text.replace(key, "[key]")
    return text or ""


def clip(text):
    text = (text or "").strip()
    if len(text) > 2000:
        return text[:2000] + " ..."
    return text


def basic_auth(key):
    raw = (key + ":").encode("utf-8")
    import base64
    return "Basic " + base64.b64encode(raw).decode("ascii")


def request_json(url, key, payload, method="POST", auth="bearer", timeout=180):
    headers = {"Accept": "application/json"}
    data = None
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    if auth == "basic":
        headers["Authorization"] = basic_auth(key)
    elif auth == "anthropic":
        headers["x-api-key"] = key
        headers["anthropic-version"] = "2023-06-01"
    elif auth == "google":
        headers["x-goog-api-key"] = key
    else:
        headers["Authorization"] = "Bearer " + key
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(req, timeout=timeout)
        raw = resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        raise HttpError(e.code, scrub(raw, key))
    except urllib.error.URLError as e:
        raise HttpError(0, scrub(str(e.reason), key))
    if not raw:
        return {}
    return json.loads(raw)


def read_text(path):
    if not os.path.isfile(path):
        return ""
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def read_meta(path):
    meta = {}
    for line in read_text(path).splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        bits = line.split(None, 1)
        meta[bits[0]] = bits[1] if len(bits) > 1 else ""
    return meta


def wants_layout(question):
    text = " " + (question or "").lower() + " "
    for phrase in (" draw ", " paint ", " place a ", " create a cell", " create the cell", " layout of"):
        if phrase in text:
            return True
    return False


def extract_plan(text):
    if not text:
        return None
    block = text.strip()
    fence = block.find("```")
    if fence >= 0:
        rest = block[fence + 3 :]
        if rest.startswith("json"):
            rest = rest[4:]
        end = rest.find("```")
        if end >= 0:
            block = rest[:end].strip()
    if not block.startswith("["):
        nl = block.find("\n[")
        if nl >= 0:
            block = block[nl + 1 :].strip()
    if not block.startswith("["):
        return None
    start = block.find("[")
    stop = block.rfind("]")
    if stop < start:
        return None
    try:
        data = json.loads(block[start : stop + 1])
    except json.JSONDecodeError:
        return None
    if not isinstance(data, list) or not data:
        return None
    if not isinstance(data[0], dict):
        return None
    if "tool" not in data[0] and "name" not in data[0]:
        return None
    return data


def value_list(param):
    out = []
    for value in param.get("values") or []:
        if isinstance(value, dict):
            out.append(str(value.get("value")))
        else:
            out.append(str(value))
    return out


def fallback_selection():
    return {
        "id": "grok-4.7",
        "params": [
            {"id": "fast", "value": "false"},
            {"id": "effort", "value": "xhigh"},
        ],
        "from_catalog": False,
        "parameters": [],
        "note": "",
    }


def pick_cursor_grok(items):
    ranked = []
    for item in items:
        if not isinstance(item, dict) or not item.get("id"):
            continue
        ident = str(item.get("id"))
        blob = " ".join(
            [
                ident,
                str(item.get("displayName") or ""),
                " ".join(str(a) for a in (item.get("aliases") or [])),
            ]
        ).lower().replace(" ", "")
        if "grok" not in blob or "4.7" not in blob:
            continue
        low = ident.lower()
        if low.endswith("-fast") or low.endswith(".fast"):
            continue
        score = 10
        if "xhigh" in low or "extra" in low:
            score += 3
        ranked.append((score, item))
    if not ranked:
        return fallback_selection()
    ranked.sort(key=lambda pair: pair[0], reverse=True)
    chosen = ranked[0][1]
    for variant in chosen.get("variants") or []:
        if not isinstance(variant, dict):
            continue
        label = str(variant.get("displayName") or "").lower()
        params = variant.get("params") or []
        if not isinstance(params, list):
            continue
        fast_true = False
        effort_ok = False
        for param in params:
            if not isinstance(param, dict):
                continue
            pid = str(param.get("id") or "")
            val = str(param.get("value") or "").lower()
            if pid == "fast" and val in ("true", "1", "yes"):
                fast_true = True
            if pid in EFFORT_IDS and val in ("xhigh", "extra-high", "extra_high"):
                effort_ok = True
        if fast_true:
            continue
        if "fast" in label and "xhigh" not in label and "extra" not in label:
            continue
        if effort_ok:
            copied = []
            for param in params:
                if isinstance(param, dict) and param.get("id"):
                    copied.append({"id": str(param["id"]), "value": str(param.get("value"))})
            return {
                "id": str(chosen["id"]),
                "params": copied,
                "parameters": chosen.get("parameters") or [],
                "from_catalog": True,
                "note": "",
            }
    params = []
    note = ""
    for param in chosen.get("parameters") or []:
        if not isinstance(param, dict):
            continue
        pid = str(param.get("id") or "")
        values = value_list(param)
        if pid == "fast":
            if "false" in values:
                params.append({"id": "fast", "value": "false"})
            elif "0" in values:
                params.append({"id": "fast", "value": "0"})
        elif pid in EFFORT_IDS:
            got = None
            for want in EFFORT_WANTS:
                if want in values:
                    got = want
                    break
            if got:
                params.append({"id": pid, "value": got})
                if got not in ("xhigh", "extra-high", "extra_high"):
                    note = "extra high is not offered for this key; using " + got
    if not params:
        params = [
            {"id": "fast", "value": "false"},
            {"id": "effort", "value": "xhigh"},
        ]
    return {
        "id": str(chosen["id"]),
        "params": params,
        "parameters": chosen.get("parameters") or [],
        "from_catalog": True,
        "note": note,
    }


def unique_params(sets):
    out = []
    seen = []
    for params in sets:
        key = json.dumps(params, sort_keys=True)
        if key in seen:
            continue
        seen.append(key)
        out.append(params)
    return out


def cursor_attempts(selection):
    params = selection["params"]
    sets = [params]
    swapped = []
    changed = False
    for param in params:
        pid = param["id"]
        if pid == "effort":
            swapped.append({"id": "reasoning", "value": param["value"]})
            changed = True
        elif pid in ("reasoning", "reasoning_effort"):
            swapped.append({"id": "effort", "value": param["value"]})
            changed = True
        else:
            swapped.append(dict(param))
    if changed:
        sets.append(swapped)
    if not selection.get("from_catalog"):
        sets.append([p for p in params if p["id"] != "fast" and "context" not in p["id"].lower()])
        sets.append([])
    without_context = [p for p in params if "context" not in p["id"].lower()]
    if without_context != params:
        sets.append(without_context)
    return unique_params(sets)


def params_safe(params, fast="0"):
    for param in params:
        if param.get("id") == "fast" and str(param.get("value")).lower() in ("true", "1", "yes"):
            if str(fast) != "1":
                return False
    return True


def cursor_options(selection, fast, context):
    want = "true" if str(fast) == "1" else "false"
    params = []
    seen_fast = False
    seen_effort = False
    for param in selection.get("params") or []:
        pid = param.get("id")
        if pid == "fast":
            params.append({"id": "fast", "value": want})
            seen_fast = True
        elif pid in EFFORT_IDS:
            params.append(dict(param))
            seen_effort = True
        elif "context" in str(pid).lower():
            continue
        else:
            params.append(dict(param))
    if not seen_fast:
        params.insert(0, {"id": "fast", "value": want})
    if not seen_effort:
        params.append({"id": "effort", "value": "xhigh"})
    extra = context_setting(selection.get("parameters"), context)
    if extra:
        params.append(extra)
    out = dict(selection)
    out["params"] = params
    return out


def context_setting(parameters, context):
    text = str(normalize_context(context))
    for param in parameters or []:
        if not isinstance(param, dict):
            continue
        pid = str(param.get("id") or "")
        low = pid.lower()
        if low not in ("context", "context_window", "max_context", "num_ctx") and "context" not in low:
            continue
        values = value_list(param)
        if not values or text in values:
            return {"id": pid, "value": text}
        nums = []
        for value in values:
            if value.isdigit():
                nums.append(int(value))
        if nums:
            target = int(text)
            best = nums[0]
            for number in nums:
                if abs(number - target) < abs(best - target):
                    best = number
            return {"id": pid, "value": str(best)}
    return None


def user_prompt(question, tech, layers):
    lines = [question.strip(), "", "Technology: " + (tech or "unknown")]
    if layers:
        lines.append("Layers: " + " ".join(layers[:80]))
    else:
        lines.append("Layers: call mcp-layers. No list was available yet.")
    lines.append("Coordinates are integer database units.")
    return "\n".join(lines)


def knowledge_path():
    root = os.path.dirname(os.path.abspath(__file__))
    for path in (
        os.path.join(root, "mcp-knowledge", "magic.txt"),
        "/mmi-pdk-live/mcp-knowledge/magic.txt",
        "/mmi-bundle/mcp-knowledge/magic.txt",
    ):
        if os.path.isfile(path):
            return path
    return ""


def knowledge_sections():
    path = knowledge_path()
    if not path:
        return []
    sections = []
    title = ""
    body = []
    for line in read_text(path).splitlines():
        if line.startswith("## "):
            if title and "".join(body).strip():
                sections.append((title, "\n".join(body).strip()))
            title = line[3:].strip()
            body = []
        else:
            body.append(line)
    if title and "".join(body).strip():
        sections.append((title, "\n".join(body).strip()))
    return sections


def retrieve_notes(question, budget):
    sections = knowledge_sections()
    if not sections:
        return ""
    try:
        budget = int(budget)
    except (TypeError, ValueError):
        budget = 4000
    if budget < 500:
        budget = 500
    words = re.findall(r"[a-z0-9]+", (question or "").lower())
    scored = []
    for index, (title, body) in enumerate(sections):
        hay_title = title.lower()
        hay = hay_title + " " + body.lower()
        score = 1 if index == 0 else 0
        for word in words:
            if len(word) < 4 and word not in ("max", "pdk", "gds", "drc"):
                continue
            if word in hay_title:
                score += 3
            elif word in hay:
                score += 1
        question_text = (question or "").lower()
        if (".max" in question_text or "max file" in question_text) and "max file" in hay_title:
            score += 6
        if ("pdk" in question_text or "tech27" in question_text) and (
            "pdk" in hay_title or "tech27" in hay
        ):
            score += 6
        scored.append((score, index, title, body))
    scored.sort(key=lambda item: (-item[0], item[1]))
    chosen = []
    used = 0
    for score, index, title, body in scored:
        if score <= 0 and chosen:
            continue
        piece = len(title) + len(body) + 2
        if chosen and used + piece > budget:
            continue
        chosen.append(index)
        used += piece
        if used >= budget:
            break
    if 0 not in chosen:
        chosen.append(0)
    parts = []
    for index, (title, body) in enumerate(sections):
        if index in chosen:
            parts.append(title + "\n" + body)
    text = "\n\n".join(parts)
    if len(text) > budget:
        text = text[:budget]
    return text


def normalize_context(value):
    try:
        number = int(str(value).strip())
    except (TypeError, ValueError):
        number = 32000
    if number < 2000:
        number = 32000
    if number > 1000000:
        number = 1000000
    return number


def context_budgets(context):
    tokens = normalize_context(context)
    chars = tokens * 3
    notes = chars // 3
    if notes > 8000:
        notes = 8000
    history = chars - notes
    if history < 1000:
        history = 1000
    return notes, history


def read_history(path):
    turns = []
    role = ""
    buf = []
    for line in read_text(path).splitlines():
        if line == "---u" or line == "---a":
            if role:
                turns.append((role, "\n".join(buf)))
            role = "u" if line == "---u" else "a"
            buf = []
        elif role:
            buf.append(line[1:] if line.startswith(" ") else line)
    if role:
        turns.append((role, "\n".join(buf)))
    return turns


def fit_history(turns, budget):
    try:
        budget = int(budget)
    except (TypeError, ValueError):
        budget = 8000
    kept = []
    used = 0
    for role, text in reversed(turns):
        size = len(text) + 8
        if kept and used + size > budget:
            break
        kept.append((role, text))
        used += size
    kept.reverse()
    return kept


def pack_turns(history, user):
    items = []
    for role, text in history:
        who = "user" if role == "u" else "assistant"
        if items and items[-1][0] == who:
            items[-1] = (who, items[-1][1] + "\n\n" + text)
        else:
            items.append((who, text))
    if items and items[-1][0] == "user":
        items[-1] = ("user", items[-1][1] + "\n\n" + user)
    else:
        items.append(("user", user))
    return items


def cursor_prompt(user, history, system):
    extra = (
        "You are answering through the Cursor agent API and cannot call these tools yourself. "
        "Answer the user's question. Remember the earlier chat. "
        "When the user wants a layout drawn, reply with only the JSON array so MAX can run the nix tools. "
        "When the user does not want a drawing, answer in plain sentences and do not emit a tool list. "
        "Do not create files and do not run shell commands.\n\n"
    )
    prior = []
    for role, text in history:
        who = "User" if role == "u" else "Assistant"
        prior.append(who + ":\n" + text)
    if prior:
        return system + "\n" + extra + "Earlier chat:\n" + "\n\n".join(prior) + "\n\nCurrent question:\n" + user
    return system + "\n" + extra + user


def model_items(payload):
    if isinstance(payload, dict):
        return payload.get("items") or payload.get("models") or []
    if isinstance(payload, list):
        return payload
    return []


def fetch_models(key):
    items = []
    cursor = None
    for _ in range(4):
        url = CURSOR + "/v1/models"
        if cursor:
            url += "?cursor=" + urllib.parse.quote(cursor)
        payload = request_json(url, key, None, method="GET", auth="basic")
        items.extend(model_items(payload))
        cursor = payload.get("nextCursor") if isinstance(payload, dict) else None
        if not cursor:
            break
    return items


def create_cursor(key, prompt, selection, fast):
    last = None
    for params in cursor_attempts(selection):
        if params == [] and selection.get("from_catalog"):
            continue
        if not params_safe(params, fast):
            continue
        if params == []:
            log("Cursor did not accept that fast and context setting. This last try uses the account default.")
        shown = " ".join(p["id"] + "=" + p["value"] for p in params) or "account default"
        log("Cursor model " + selection["id"] + " " + shown)
        body = {
            "prompt": {"text": prompt},
            "mode": "plan",
            "model": {"id": selection["id"]},
        }
        if params:
            body["model"]["params"] = params
        try:
            return request_json(CURSOR + "/v1/agents", key, body, auth="basic", timeout=180)
        except HttpError as e:
            last = e
            if e.code in (401, 403):
                raise
            if e.code not in (400, 422):
                raise
            log("Cursor refused that setting: " + scrub(e.body, key)[:240])
    if last:
        raise last
    raise HttpError(400, "no safe model setting to try")


def iter_sse(resp):
    event = "message"
    data = []
    for raw in resp:
        line = raw.decode("utf-8", "replace").rstrip("\r\n")
        if line == "":
            if data:
                yield event, "\n".join(data)
            event = "message"
            data = []
            continue
        if line.startswith(":"):
            continue
        if line.startswith("event:"):
            event = line[6:].strip()
        elif line.startswith("data:"):
            payload = line[5:]
            if payload.startswith(" "):
                payload = payload[1:]
            data.append(payload)
    if data:
        yield event, "\n".join(data)


def stream_run(key, agent_id, run_id, job):
    url = (
        CURSOR
        + "/v1/agents/"
        + urllib.parse.quote(agent_id)
        + "/runs/"
        + urllib.parse.quote(run_id)
        + "/stream"
    )
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": basic_auth(key),
            "Accept": "text/event-stream",
        },
    )
    assistant = []
    result_text = ""
    result_status = ""
    thinking = False
    deadline = time.time() + 900
    try:
        resp = urllib.request.urlopen(req, timeout=120)
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        raise HttpError(e.code, scrub(raw, key))
    except urllib.error.URLError as e:
        raise HttpError(0, scrub(str(e.reason), key))
    with resp:
        for event, payload in iter_sse(resp):
            if time.time() > deadline:
                fail("Timed out waiting for Grok 4.7.")
            if cancelled(job):
                fail("Stopped.")
            if event == "thinking" and not thinking:
                log("Grok 4.7 is thinking.")
                thinking = True
            elif event == "assistant":
                try:
                    obj = json.loads(payload)
                except json.JSONDecodeError:
                    continue
                piece = obj.get("text") or ""
                if piece:
                    assistant.append(piece)
            elif event == "tool_call":
                try:
                    obj = json.loads(payload)
                except json.JSONDecodeError:
                    continue
                if obj.get("status") == "running":
                    log("cloud tool " + str(obj.get("name") or ""))
            elif event == "result":
                try:
                    obj = json.loads(payload)
                except json.JSONDecodeError:
                    continue
                result_status = str(obj.get("status") or "")
                result_text = obj.get("text") or ""
            elif event == "error":
                try:
                    obj = json.loads(payload)
                    msg = obj.get("message") or payload
                except json.JSONDecodeError:
                    msg = payload
                raise HttpError(0, scrub(str(msg), key))
            elif event == "done":
                break
    text = result_text or "".join(assistant)
    if result_status and result_status.upper() not in ("FINISHED", ""):
        if not text:
            fail("Cursor run " + result_status)
        log("Cursor run " + result_status)
    return text


def cursor_ask(key, question, tech, layers, job, history, system, fast, context):
    try:
        selection = pick_cursor_grok(fetch_models(key))
    except HttpError as e:
        if e.code in (401, 403):
            fail("Cursor rejected the API key.")
        log("Could not list Cursor models. Using grok-4.7, extra high.")
        selection = fallback_selection()
    selection = cursor_options(selection, fast, context)
    if selection.get("note"):
        log(selection["note"])
    if str(fast) == "1":
        log("Cursor fast mode is on. Context window " + str(normalize_context(context)) + " tokens.")
    else:
        log("Cursor fast mode is off. Context window " + str(normalize_context(context)) + " tokens.")
    prompt = cursor_prompt(user_prompt(question, tech, layers), history, system)
    created = create_cursor(key, prompt, selection, fast)
    agent = created.get("agent") or {}
    run = created.get("run") or {}
    agent_id = agent.get("id") or ""
    run_id = run.get("id") or agent.get("latestRunId") or ""
    if not agent_id or not run_id:
        fail("Cursor did not return an agent run.")
    if agent.get("url"):
        log("Cursor run " + str(agent.get("url")))
    try:
        text = stream_run(key, agent_id, run_id, job)
        if wants_layout(question) and extract_plan(text) is None:
            log("Asking again for the layout steps only.")
            try:
                follow = request_json(
                    CURSOR + "/v1/agents/" + urllib.parse.quote(agent_id) + "/runs",
                    key,
                    {
                        "prompt": {
                            "text": "Reply with only a JSON array of tool calls that draws the layout. No prose and no markdown."
                        },
                        "mode": "plan",
                    },
                    auth="basic",
                )
                run2 = (follow.get("run") or {}).get("id") or ""
                if run2:
                    text = stream_run(key, agent_id, run2, job)
            except HttpError as e:
                log("Could not ask again: " + scrub(e.body, key)[:200])
        return text
    finally:
        try:
            request_json(
                CURSOR + "/v1/agents/" + urllib.parse.quote(agent_id) + "/archive",
                key,
                {},
                auth="basic",
            )
        except Exception:
            pass


def num(step, key):
    if key not in step:
        raise ValueError("missing " + key)
    value = step[key]
    if isinstance(value, bool) or not isinstance(value, (int, float, str)):
        raise ValueError(key + " is not an integer")
    if isinstance(value, float) and not value.is_integer():
        raise ValueError(key + " is not an integer")
    if isinstance(value, str):
        if not re.fullmatch(r"-?\d+", value):
            raise ValueError(key + " is not an integer")
        return str(int(value))
    return str(int(value))


def normalize(step):
    if not isinstance(step, dict):
        raise ValueError("a step must be an object")
    name = step.get("tool") or step.get("name")
    if name not in TOOLS:
        raise ValueError("unknown tool " + str(name))
    if name == "mcp-layers":
        return name, []
    if name == "mcp-cell":
        cell = step.get("cell") or ""
        if not cell and step.get("tool") == "mcp-cell":
            cell = step.get("name") or ""
        if not cell:
            args = step.get("args") or []
            if args:
                return name, ["--name", str(args[0])]
            raise ValueError("mcp-cell needs a name")
        return name, ["--name", str(cell)]
    if name == "mcp-paint":
        if "layer" in step:
            return name, [
                "--layer",
                str(step["layer"]),
                "--x1",
                num(step, "x1"),
                "--y1",
                num(step, "y1"),
                "--x2",
                num(step, "x2"),
                "--y2",
                num(step, "y2"),
                "--note",
                str(step.get("note") or ""),
            ]
        args = step.get("args") or []
        if len(args) >= 5:
            argv = [
                "--layer",
                str(args[0]),
                "--x1",
                str(int(args[1])),
                "--y1",
                str(int(args[2])),
                "--x2",
                str(int(args[3])),
                "--y2",
                str(int(args[4])),
                "--note",
                str(args[5]) if len(args) >= 6 else "",
            ]
            return name, argv
        raise ValueError("mcp-paint needs a layer and a box")
    if name == "mcp-label":
        if "text" in step:
            return name, [
                "--layer",
                str(step["layer"]),
                "--text",
                str(step["text"]),
                "--x",
                num(step, "x"),
                "--y",
                num(step, "y"),
            ]
        args = step.get("args") or []
        if len(args) >= 4:
            return name, ["--layer", str(args[0]), "--text", str(args[1]), "--x", str(int(args[2])), "--y", str(int(args[3]))]
        raise ValueError("mcp-label needs a layer, text, and a point")
    if name == "mcp-zoom":
        if "x1" in step:
            return name, ["--x1", num(step, "x1"), "--y1", num(step, "y1"), "--x2", num(step, "x2"), "--y2", num(step, "y2")]
        args = step.get("args") or []
        if len(args) >= 4:
            return name, ["--x1", str(int(args[0])), "--y1", str(int(args[1])), "--x2", str(int(args[2])), "--y2", str(int(args[3]))]
        raise ValueError("mcp-zoom needs a box")
    pkg = str(step.get("package") or "")
    args = step.get("args") or []
    if isinstance(args, str):
        args = args.split()
    if not pkg and args:
        pkg = str(args[0])
        args = args[1:]
    if not pkg:
        raise ValueError("mcp-nix needs a package")
    return name, [pkg] + [str(a) for a in args]


def cancelled(job):
    return os.path.exists(os.path.join(job, "cancel"))


def resolve_tool(name):
    extra = os.environ.get("MAX_MCP_TOOLS", "")
    if extra:
        candidate = os.path.join(extra, name)
        if os.path.isfile(candidate):
            if os.access(candidate, os.X_OK):
                return [candidate]
            return ["sh", candidate]
    found = shutil.which(name)
    if found:
        return [found]
    return None


def tool_env(name, job):
    env = {
        "PATH": os.environ.get("PATH", ""),
        "LANG": "C",
        "LC_ALL": "C",
        "TZ": os.environ.get("TZ", "UTC"),
        "HOME": os.path.join(job, "nixscratch"),
    }
    if name != "mcp-nix":
        env["MAX_MCP_DIR"] = job
        tools = os.environ.get("MAX_MCP_TOOLS", "")
        if tools:
            env["MAX_MCP_TOOLS"] = tools
    return env


def run_tool(name, argv, job):
    if cancelled(job):
        fail("Stopped.")
    cmd = resolve_tool(name)
    if not cmd:
        fail(name + " is not on PATH. It is part of the mmi-mcp-tools nix package.")
    log("run " + name + " " + " ".join(argv))
    scratch = os.path.join(job, "nixscratch")
    if name == "mcp-nix":
        os.makedirs(scratch, exist_ok=True)
    try:
        proc = subprocess.run(
            cmd + list(argv),
            capture_output=True,
            text=True,
            timeout=180,
            cwd=scratch if name == "mcp-nix" else None,
            env=tool_env(name, job),
        )
    except subprocess.TimeoutExpired:
        return "error: " + name + " timed out"
    out = proc.stdout or ""
    if proc.stderr:
        out = (out + "\n" + proc.stderr).strip()
    if proc.returncode != 0:
        return "error: " + (clip(out) or ("exit " + str(proc.returncode)))
    return clip(out) or "ok"


def call_obj(name, obj, job):
    if not isinstance(obj, dict):
        obj = {}
    step = dict(obj)
    step["tool"] = name
    try:
        tool, argv = normalize(step)
    except ValueError as e:
        return "error: " + str(e)
    return run_tool(tool, argv, job)


def run_plan(steps, job):
    if len(steps) > 40:
        log("Only the first 40 steps are drawn.")
        steps = steps[:40]
    n = 0
    for step in steps:
        try:
            name, argv = normalize(step)
        except ValueError as e:
            fail(str(e))
        out = run_tool(name, argv, job)
        n += 1
        if out.startswith("error:"):
            log(out)
            fail("Stopped on " + name + ".")
    log("Drew " + str(n) + " steps.")


def deliver(text, question, job, drew):
    plan = extract_plan(text or "")
    prose = (text or "").strip()
    if wants_layout(question) and plan and not drew:
        run_plan(plan, job)
        say("Drew the requested layout, one shape at a time.")
        return
    if prose:
        say(prose)
    else:
        say("(no reply)")


def openai_tools():
    def fn(name, desc, props, required):
        return {
            "type": "function",
            "function": {
                "name": name,
                "description": desc,
                "parameters": {
                    "type": "object",
                    "properties": props,
                    "required": required,
                },
            },
        }

    box = {
        "x1": {"type": "integer"},
        "y1": {"type": "integer"},
        "x2": {"type": "integer"},
        "y2": {"type": "integer"},
    }
    return [
        fn("mcp-layers", "List technology layers in MAX.", {}, []),
        fn("mcp-cell", "Create a cell and edit it.", {"cell": {"type": "string"}}, ["cell"]),
        fn(
            "mcp-paint",
            "Paint one rectangle so the user can see that step.",
            dict(box, layer={"type": "string"}, note={"type": "string"}),
            ["layer", "x1", "y1", "x2", "y2"],
        ),
        fn(
            "mcp-label",
            "Place one label.",
            {"layer": {"type": "string"}, "text": {"type": "string"}, "x": {"type": "integer"}, "y": {"type": "integer"}},
            ["layer", "text", "x", "y"],
        ),
        fn("mcp-zoom", "Zoom the window to a box.", box, ["x1", "y1", "x2", "y2"]),
        fn(
            "mcp-nix",
            "Run one nix package: magic, ngspice, gawk, convert, magick, or identify.",
            {"package": {"type": "string"}, "args": {"type": "array", "items": {"type": "string"}}},
            ["package"],
        ),
    ]


def content_text(content):
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        bits = []
        for part in content:
            if isinstance(part, str):
                bits.append(part)
            elif isinstance(part, dict):
                bits.append(part.get("text") or "")
        return "".join(bits)
    return str(content)


def post_openai(agent, key, body):
    try:
        return request_json(OPENAI_URLS[agent], key, body, auth="bearer")
    except HttpError as e:
        if e.code == 400 and "reasoning_effort" in body and "reasoning" in e.body.lower():
            log("This agent rejected the effort setting. Asking again without it.")
            retry = dict(body)
            retry.pop("reasoning_effort", None)
            return request_json(OPENAI_URLS[agent], key, retry, auth="bearer")
        raise


def openai_loop(agent, key, model, effort, user, job, history, system):
    messages = [{"role": "system", "content": system}]
    for role, text in pack_turns(history, user):
        messages.append({"role": role, "content": text})
    drew = False
    tools = openai_tools()
    for _ in range(24):
        if cancelled(job):
            fail("Stopped.")
        body = {"model": model, "messages": messages, "tools": tools}
        if agent == "xai" and effort:
            body["reasoning_effort"] = effort
        try:
            data = post_openai(agent, key, body)
        except HttpError as e:
            if e.code == 400 and "tool" in e.body.lower():
                log("This agent does not accept tools. Asking for a JSON plan instead.")
                plain = dict(body)
                plain.pop("tools", None)
                plain.pop("reasoning_effort", None)
                data = request_json(OPENAI_URLS[agent], key, plain, auth="bearer")
                return content_text((data.get("choices") or [{}])[0].get("message", {}).get("content")), drew
            raise
        message = (data.get("choices") or [{}])[0].get("message") or {}
        calls = message.get("tool_calls") or []
        if not calls:
            return content_text(message.get("content")), drew
        drew = True
        messages.append(
            {
                "role": "assistant",
                "content": content_text(message.get("content")),
                "tool_calls": calls,
            }
        )
        for call in calls:
            fn = call.get("function") or {}
            raw = fn.get("arguments") or "{}"
            try:
                obj = json.loads(raw) if isinstance(raw, str) else (raw or {})
            except json.JSONDecodeError:
                obj = {}
            out = call_obj(fn.get("name"), obj, job)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": call.get("id"),
                    "content": out,
                }
            )
    fail("Too many tool steps.")


def anthropic_tools():
    def spec(name, desc, props, required):
        return {
            "name": name,
            "description": desc,
            "input_schema": {"type": "object", "properties": props, "required": required},
        }

    box = {
        "x1": {"type": "integer"},
        "y1": {"type": "integer"},
        "x2": {"type": "integer"},
        "y2": {"type": "integer"},
    }
    return [
        spec("mcp-layers", "List technology layers in MAX.", {}, []),
        spec("mcp-cell", "Create a cell and edit it.", {"cell": {"type": "string"}}, ["cell"]),
        spec(
            "mcp-paint",
            "Paint one rectangle so the user can see that step.",
            dict(box, layer={"type": "string"}, note={"type": "string"}),
            ["layer", "x1", "y1", "x2", "y2"],
        ),
        spec(
            "mcp-label",
            "Place one label.",
            {"layer": {"type": "string"}, "text": {"type": "string"}, "x": {"type": "integer"}, "y": {"type": "integer"}},
            ["layer", "text", "x", "y"],
        ),
        spec("mcp-zoom", "Zoom the window to a box.", box, ["x1", "y1", "x2", "y2"]),
        spec(
            "mcp-nix",
            "Run one nix package: magic, ngspice, gawk, convert, magick, or identify.",
            {"package": {"type": "string"}, "args": {"type": "array", "items": {"type": "string"}}},
            ["package"],
        ),
    ]


def anthropic_loop(key, model, user, job, history, system):
    messages = [{"role": role, "content": text} for role, text in pack_turns(history, user)]
    drew = False
    for _ in range(24):
        if cancelled(job):
            fail("Stopped.")
        data = request_json(
            "https://api.anthropic.com/v1/messages",
            key,
            {
                "model": model,
                "max_tokens": 4096,
                "system": system,
                "tools": anthropic_tools(),
                "messages": messages,
            },
            auth="anthropic",
        )
        content = data.get("content") or []
        messages.append({"role": "assistant", "content": content})
        calls = [b for b in content if isinstance(b, dict) and b.get("type") == "tool_use"]
        texts = [b.get("text") or "" for b in content if isinstance(b, dict) and b.get("type") == "text"]
        if not calls:
            return "\n".join(texts), drew
        drew = True
        results = []
        for call in calls:
            out = call_obj(call.get("name"), call.get("input") or {}, job)
            results.append({"type": "tool_result", "tool_use_id": call.get("id"), "content": out})
        messages.append({"role": "user", "content": results})
    fail("Too many tool steps.")


def google_model(model):
    name = (model or "").strip()
    if name.startswith("models/"):
        name = name[len("models/") :]
    if name == "gemini-2.5-pro":
        name = "gemini-3.1-pro-preview"
    return name


def google_text(key, model, user, history, system):
    raw = (model or "").strip()
    if raw.startswith("models/"):
        raw = raw[len("models/") :]
    if raw == "gemini-2.5-pro":
        log("Google retired gemini-2.5-pro. Using gemini-3.1-pro-preview.")
    model = google_model(model)
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        + urllib.parse.quote(model, safe="")
        + ":generateContent"
    )
    contents = []
    first = True
    for role, text in pack_turns(history, user):
        grole = "user" if role == "user" else "model"
        if first and grole == "user":
            text = system + "\n\n" + text
            first = False
        contents.append({"role": grole, "parts": [{"text": text}]})
    data = request_json(
        url,
        key,
        {"contents": contents},
        auth="google",
    )
    parts = (((data.get("candidates") or [{}])[0].get("content") or {}).get("parts")) or []
    return "".join(p.get("text") or "" for p in parts if isinstance(p, dict))


def cohere_text(key, model, user, history, system):
    messages = [{"role": "system", "content": system}]
    for role, text in pack_turns(history, user):
        messages.append({"role": role, "content": text})
    data = request_json(
        "https://api.cohere.com/v2/chat",
        key,
        {"model": model, "messages": messages},
        auth="bearer",
    )
    content = (data.get("message") or {}).get("content") or ""
    if isinstance(content, str):
        return content
    return "".join(p.get("text") or "" for p in content if isinstance(p, dict))


def load_key(agent, home):
    found = ""
    model = ""
    effort = ""
    fast = "0"
    context = ""
    path = os.path.join(home, "keys")
    if os.path.isfile(path):
        for line in read_text(path).splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.split("\t")
            while len(parts) < 6:
                parts.append("")
            if parts[0] == agent:
                found, model, effort, fast, context = parts[1], parts[2], parts[3], parts[4], parts[5]
                break
    if agent == "cursor":
        model, effort = "grok-4.7", "xhigh"
        if fast != "1":
            fast = "0"
        context = str(normalize_context(context))
    if not found:
        fail("No API key for " + agent + ". Open the mcp menu and paste the key in the box.")
    return found, model, effort, fast, context


def settings_for(agent, meta, home):
    key, model, effort, fast, context = load_key(agent, home)
    if agent == "cursor":
        model, effort = "grok-4.7", "xhigh"
        if meta.get("fast") in ("0", "1"):
            fast = meta["fast"]
        if meta.get("context"):
            context = str(normalize_context(meta.get("context")))
        return key, model, effort, fast, context
    if meta.get("model"):
        model = meta["model"]
    if "effort" in meta:
        effort = meta["effort"]
    if meta.get("fast"):
        fast = meta["fast"]
    if not model:
        fail("No model is set for " + agent + ".")
    return key, model, effort, fast, "32000"


def run_job(job):
    meta = read_meta(os.path.join(job, "meta"))
    agent = meta.get("agent") or "cursor"
    home = os.environ.get("MAX_MCP_HOME") or os.path.join(os.environ.get("HOME", "/mmi-home"), ".max-mcp")
    question = read_text(os.path.join(job, "question.txt"))
    layers = [ln.strip() for ln in read_text(os.path.join(job, "layers.txt")).splitlines() if ln.strip()]
    tech = meta.get("tech") or ""
    key, model, effort, fast, context = settings_for(agent, meta, home)
    note_budget, history_budget = context_budgets(context)
    notes = retrieve_notes(question, note_budget)
    system = SYSTEM
    if notes:
        system = (
            SYSTEM
            + "\n\nReference notes from the Magic guide. Use them for the editor, .max files, and the open PDK technology. "
            + "They are not a request to draw.\n\n"
            + notes
        )
    history = fit_history(read_history(os.path.join(job, "history.txt")), history_budget)
    user = user_prompt(question, tech, layers)
    drew = False
    if agent == "cursor":
        text = cursor_ask(key, question, tech, layers, job, history, system, fast, context)
    elif agent == "anthropic":
        text, drew = anthropic_loop(key, model, user, job, history, system)
    elif agent == "google":
        text = google_text(key, model, user, history, system)
    elif agent == "cohere":
        text = cohere_text(key, model, user, history, system)
    elif agent in OPENAI_URLS:
        if fast == "1":
            log(agent + " fast is on. Model " + model)
        text, drew = openai_loop(agent, key, model, effort, user, job, history, system)
    else:
        fail("Unknown agent " + agent)
    deliver(text, question, job, drew)


def selftest():
    failed = 0

    def check(name, cond):
        nonlocal failed
        if not cond:
            print("FAIL " + name)
            failed += 1

    catalog = {
        "items": [
            {
                "id": "grok-4.7-fast",
                "displayName": "Grok 4.7 Fast",
                "parameters": [{"id": "fast", "values": [{"value": "true"}, {"value": "false"}]}],
            },
            {
                "id": "grok-4.7",
                "displayName": "Grok 4.7",
                "parameters": [
                    {"id": "fast", "values": [{"value": "true"}, {"value": "false"}]},
                    {
                        "id": "effort",
                        "values": [
                            {"value": "low"},
                            {"value": "medium"},
                            {"value": "high"},
                            {"value": "xhigh"},
                        ],
                    },
                ],
                "variants": [
                    {
                        "displayName": "Grok 4.7 Fast",
                        "isDefault": True,
                        "params": [
                            {"id": "fast", "value": "true"},
                            {"id": "effort", "value": "high"},
                        ],
                    },
                    {
                        "displayName": "Grok 4.7 Extra High",
                        "params": [
                            {"id": "fast", "value": "false"},
                            {"id": "effort", "value": "xhigh"},
                        ],
                    },
                ],
            },
        ]
    }
    picked = pick_cursor_grok(catalog["items"])
    check("grok id", picked["id"] == "grok-4.7")
    check("not fast", {"id": "fast", "value": "false"} in picked["params"])
    check("xhigh", {"id": "effort", "value": "xhigh"} in picked["params"])
    check("safe", params_safe(picked["params"]))
    for attempt in cursor_attempts(picked):
        check("attempt safe", params_safe(attempt))

    reasoning = pick_cursor_grok(
        [
            {
                "id": "grok-4.7",
                "displayName": "Grok 4.7",
                "parameters": [
                    {"id": "fast", "values": [{"value": "false"}, {"value": "true"}]},
                    {"id": "reasoning", "values": [{"value": "low"}, {"value": "xhigh"}]},
                ],
            }
        ]
    )
    check("reasoning xhigh", {"id": "reasoning", "value": "xhigh"} in reasoning["params"])
    check("reasoning fast off", {"id": "fast", "value": "false"} in reasoning["params"])

    missing = pick_cursor_grok([{"id": "composer-2.5", "displayName": "Composer"}])
    check("fallback id", missing["id"] == "grok-4.7")
    check("fallback catalog", missing["from_catalog"] is False)
    check("fallback safe", params_safe(missing["params"]))

    plan = extract_plan(
        '```json\n[{"tool":"mcp-cell","name":"inv"},{"tool":"mcp-paint","layer":"poly","x1":0,"y1":0,"x2":8,"y2":40,"note":"gate"}]\n```'
    )
    check("plan len", plan is not None and len(plan) == 2)
    check("prose", extract_plan("A via connects two metal layers.") is None)
    if plan:
        tool, argv = normalize(plan[0])
        check("cell tool", tool == "mcp-cell" and argv == ["--name", "inv"])
        tool, argv = normalize(plan[1])
        check("paint tool", tool == "mcp-paint" and "--layer" in argv and "poly" in argv)
    check("draw question", wants_layout("Draw the layout of a very simple CMOS inverter"))
    check("plain question", not wants_layout("What is a via?"))
    check("flyline question", not wants_layout("How does a flyline work?"))
    check("editor question", not wants_layout("How does the layout editor work?"))
    notes = retrieve_notes("what is a flyline", 5000)
    check("notes flyline", "label" in notes.lower() and "flyline" in notes.lower())
    max_notes = retrieve_notes("how does a .max file work", 8000).lower()
    check("notes max", "resolution" in max_notes and "tech name" in max_notes)
    pdk_notes = retrieve_notes("how should I handle pdk tech", 8000).lower()
    check("notes pdk", "tech27" in pdk_notes and "not in this technology" in pdk_notes)
    fast_on = cursor_options(picked, "1", "16000")
    check("fast on", {"id": "fast", "value": "true"} in fast_on["params"])
    check("fast allowed", params_safe(fast_on["params"], "1"))
    check("fast keeps effort", {"id": "effort", "value": "xhigh"} in fast_on["params"])
    setting = context_setting(
        [{"id": "context_window", "values": [{"value": "8000"}, {"value": "32000"}]}],
        "16000",
    )
    check("context nearest", setting == {"id": "context_window", "value": "8000"})
    check("context absent", context_setting([{"id": "fast", "values": [{"value": "true"}]}], "32000") is None)
    kept = fit_history([("u", "old"), ("a", "older answer"), ("u", "new")], 20)
    check("history newest", kept[-1] == ("u", "new"))
    import tempfile
    handle = tempfile.NamedTemporaryFile(mode="w", delete=False, encoding="utf-8")
    handle.write("---u\n what is a flyline?\n---a\n It joins two labels.\n")
    handle.close()
    turns = read_history(handle.name)
    os.remove(handle.name)
    check("history read", turns == [("u", "what is a flyline?"), ("a", "It joins two labels.")])
    packed = pack_turns([("u", "Earlier"), ("a", "A flyline joins labels.")], "And now?")
    check("packed memory", packed[0] == ("user", "Earlier") and packed[1][0] == "assistant" and packed[2][0] == "user")
    check("google retired", google_model("gemini-2.5-pro") == "gemini-3.1-pro-preview")
    check("google prefix", google_model("models/gemini-2.5-pro") == "gemini-3.1-pro-preview")
    check("google current", google_model("gemini-3.1-pro-preview") == "gemini-3.1-pro-preview")

    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "mcp-tools")
    nix = open(os.path.join(root, "mcp-nix"), "r", encoding="utf-8").read()
    for pkg in NIX_PACKAGES:
        check("nix " + pkg, pkg in nix)
    for name in ("mcp-io", "mcp-layers", "mcp-cell", "mcp-paint", "mcp-label", "mcp-zoom", "mcp-nix"):
        check("tool " + name, os.path.isfile(os.path.join(root, name)))
    check("paint uses io", "mcp-io" in open(os.path.join(root, "mcp-paint"), "r", encoding="utf-8").read())

    if failed:
        sys.exit(1)
    print("mcp_ask selftest ok")


def main():
    try:
        if len(sys.argv) >= 2 and sys.argv[1] == "--selftest":
            selftest()
            return
        if len(sys.argv) != 2:
            fail("usage: mcp_ask.py JOBDIR")
        run_job(sys.argv[1])
        print("DONE", flush=True)
    except HttpError as e:
        fail("HTTP " + str(e.code) + " " + e.body[:500])


if __name__ == "__main__":
    main()
