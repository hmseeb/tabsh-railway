#!/usr/bin/env python3
"""Publish the template written by upsert.py. Railway mints the slug from the name
at first publish and never changes it; re-running only refreshes listing copy.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path("~/.claude/skills/create-template-for-railway/scripts").expanduser()))
import rw  # noqa: E402

HERE = pathlib.Path(__file__).parent
TEMPLATE = (HERE / "template-id").read_text().strip()
WORKSPACE = "fc4796db-2c6c-4354-a564-d4a1d900af53"  # Auromations
NAME = "tabsh"
DESCRIPTION = "Browser terminal and kanban board for Claude Code, Codex and other agents"
CATEGORY = "AI/ML"
ICON = "https://tabsh.cc/app/icon-512.png"
README = (HERE / "TEMPLATE_OVERVIEW.md").read_text()

assert len(DESCRIPTION) <= 75, len(DESCRIPTION)
assert "—" not in README + DESCRIPTION, "no em dashes in listing copy"

rw.gql("mutation($id:String!,$input:TemplateUpsertSettingsInput!){templateUpsertSettings(id:$id,input:$input){id}}",
       {"id": TEMPLATE, "input": {"workspaceId": WORKSPACE, "name": NAME, "description": DESCRIPTION, "image": ICON}},
       internal=True)
out = rw.gql("mutation($id:String!,$input:TemplatePublishInput!){templatePublish(id:$id,input:$input){code name status}}",
             {"id": TEMPLATE, "input": {"category": CATEGORY, "description": DESCRIPTION,
                                        "readme": README, "workspaceId": WORKSPACE}})["templatePublish"]
print(f"{out['name']}  ->  https://railway.com/deploy/{out['code']}   ({out['status']})")
