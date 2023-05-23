# Container Agent Helm Chart Changelog

This is the Container Agent Helm Chart changelog

# 101.0.1

Remove command from agent pod spec to use command specified in the image Dockerfile

# 101.0.0

Update default image repository to `circleci/runner-agent`

## 100.0.1

Set custom service account even if `create` is set to `false` ([PR #5](https://github.com/CircleCI-Public/container-runner-helm-chart/pull/5))

## 100.0.0 

Initial release of helm chart
