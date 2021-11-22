"""
This module contains terraform steps for deploying the dependant database
"""
tf_version = "1.0.8"
tf_image = "jmccann/drone-terraform:8.3-1.0.2"
tf_root_dir = "terraform/"

branches = {
    "main": ["main", "master"],
    "feature": {
        "exclude": ["main", "master"],
    },
}

def tf_apply_when(env):
    if env == "production":
        return {"event": ["promote"], "target": [env], "branch": branches["main"]}
    elif env == "staging":
        return {"event": ["push"], "branch": branches["main"]}
    elif env == "uat":
        return {"event": ["promote"], "target": [env]}
    else:
        return {}

def tf_sec_step():
    return {
        "name": "tfsec",
        "image": "quay.io/fundingcircle/drone-tfsec:1",
        "settings": {
            "root_dir": tf_root_dir,
        },
        "depends_on": ["clone"],
    }

def tf_plan_step(env):
    return {
        "name": "plan_{}".format(env),
        "image": tf_image,
        "settings": {
            "root_dir": "terraform",
            "tf_data_dir": ".terraform-{}".format(env),
            "tf_version": tf_version,
            "init_options": {
                "backend-config": [
                    "config/{}/terraform.remote".format(env),
                    "key=eu-west-1/${{DRONE_REPO_NAME}}/{}.tfstate".format(env),
                ],
            },
            "var_files": [
                "config/{}/terraform.tfvars".format(env),
            ],
            "actions": ["fmt", "validate", "plan"],
            "fmt_options": {
                "check": "true",
                "diff": "true",
            },
        },
        "depends_on": ["tfsec"],
    }

def tf_apply_step(env, depends_on = ""):
    step = {
        "name": "apply_{}".format(env),
        "image": tf_image,
        "settings": {
            "root_dir": "terraform",
            "tf_data_dir": ".terraform-{}".format(env),
            "tf_version": tf_version,
            "init_options": {
                "backend-config": [
                    "config/{}/terraform.remote".format(env),
                    "key=eu-west-1/${{DRONE_REPO_NAME}}/{}.tfstate".format(env),
                ],
            },
            "var_files": [
                "config/{}/terraform.tfvars".format(env),
            ],
        },
        "depends_on": ["tfsec", "plan_{}".format(env)],
        "when": tf_apply_when(env),
    }

    if len(depends_on) > 0:
        step["depends_on"].append(depends_on)

    return step

def tf_comment_step(env):
    return {
        "name": "comment_{}".format(env),
        "image": "robertstettner/drone-terraform-github-commenter:1-0.13.2",
        "environment": {
            "GITHUB_TOKEN": {"from_secret": "github_token"},
        },
        "settings": {
            "title": "Terraform Plan Output - {}".format(env.title()),
            "root_dir": "terraform",
            "tf_data_dir": ".terraform-{}".format(env),
            "tf_version": tf_version,
            "init_options": {
                "backend-config": [
                    "config/{}/terraform.remote".format(env),
                    "key=eu-west-1/${{DRONE_REPO_NAME}}/{}.tfstate".format(env),
                ],
            },
            "var_files": [
                "config/{}/terraform.tfvars".format(env),
            ],
        },
        "depends_on": ["plan_{}".format(env)],
        "when": {"event": "push", "branch": branches["feature"]},
    }

def tf_pipeline(ctx):
    return {
        "name": "terraform",
        "kind": "pipeline",
        "clone": {"depth": 1},
        "concurrency": {"limit": 1},
        "steps": [
            tf_sec_step(),
            tf_plan_step("uat"),
            tf_plan_step("staging"),
            tf_plan_step("production"),
            tf_comment_step("uat"),
            tf_comment_step("staging"),
            tf_comment_step("production"),
            tf_apply_step("uat"),
            tf_apply_step("staging"),
            tf_apply_step("production", "apply_staging"),
        ],
        "trigger": {
            "event": ["push", "promote"],
        },
    }

def main(ctx):
    return [
        tf_pipeline(ctx)
    ]