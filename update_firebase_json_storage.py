import json
from pathlib import Path

path = Path("firebase.json")

if path.exists():
    data = json.loads(path.read_text(encoding="utf-8"))
else:
    data = {}

data["storage"] = {
    "rules": "infra/rules/storage.rules"
}

if "firestore" not in data:
    data["firestore"] = {
        "rules": "infra/rules/firestore.rules",
        "indexes": "infra/rules/firestore.indexes.json"
    }

path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
print("firebase.json güncellendi.")
