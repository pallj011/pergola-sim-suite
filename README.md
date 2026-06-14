# pergola-sim-suite

A Helm chart that deploys a GPU-accelerated simulation suite — **Gazebo**,
**MATLAB**, and **Simulink** — onto Kubernetes as a single release.

- 📖 Full configuration and usage: **[USAGE.md](USAGE.md)**
- 📦 Chart source: [`charts/pergola-sim-suite`](charts/pergola-sim-suite)

## Install from the Helm repository

> Published to GitHub Pages by the `release.yaml` workflow once Pages is enabled.

```bash
helm repo add pergola https://pallj011.github.io/pergola-sim-suite
helm repo update
helm install sims pergola/pergola-sim-suite \
  --set global.mathworks.acceptLicense=true \
  --set global.mathworks.licenseServer="27000@license.example.com" \
  --set gazebo.image.repository=YOUR_REGISTRY/gazebo \
  --set gazebo.image.tag=YOUR_TAG
```

## Install from source

```bash
git clone https://github.com/pallj011/pergola-sim-suite
helm install sims ./pergola-sim-suite/charts/pergola-sim-suite -f my-values.yaml
```

## Publishing (maintainers)

Charts are released automatically by [chart-releaser](https://github.com/helm/chart-releaser-action):

1. Bump `version:` in `charts/pergola-sim-suite/Chart.yaml`.
2. Merge to `main`. The **Release Charts** workflow packages the chart, creates
   a GitHub Release with the `.tgz`, and updates `index.yaml` on the `gh-pages`
   branch.
3. **One-time setup:** in repo **Settings → Pages**, set the source to the
   `gh-pages` branch (root). Ensure **Settings → Actions → General → Workflow
   permissions** allows read/write so the workflow can push to `gh-pages`.

Pull requests touching `charts/**` are linted by the **Lint Charts** workflow
(`ct lint`). Install testing is omitted from CI because MATLAB requires a
license server and the Gazebo image is user-supplied.

## License

[Apache 2.0](LICENSE)
