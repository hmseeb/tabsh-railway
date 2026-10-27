#!/usr/bin/env python3
"""Deploy the template into a fresh project exactly like Railway's deploy button.
Usage: deploy_as_stranger.py <template-code>   (deploys into My Projects, see AGENTS.md)
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path("~/.claude/skills/create-template-for-railway/scripts").expanduser()))
import rw  # noqa: E402

WORKSPACE = "d10da65a-297f-4ba4-8cef-2fa9bb45fdef"  # My Projects (Auromations billing paused)
template = rw.gql("query($c:String!){template(code:$c){id serializedConfig}}", {"c": sys.argv[1]})["template"]
out = rw.gql("mutation($input:TemplateDeployV2Input!){templateDeployV2(input:$input){projectId workflowId}}",
             {"input": {"templateId": template["id"], "workspaceId": WORKSPACE,
                        "serializedConfig": template["serializedConfig"]}})["templateDeployV2"]
print(json.dumps(out, indent=2))
