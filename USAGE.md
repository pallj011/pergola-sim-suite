# Pergola Sim Suite — Usage Guide

This repository contains **`pergola-sim-suite`**, a Helm chart that deploys a
GPU-accelerated simulation suite onto Kubernetes as a single release:

| Component   | What it is                                                | Workload    | GPU      |
|-------------|-----------------------------------------------------------|-------------|----------|
| **Gazebo**  | GPU-accelerated robotics simulators, run as a fleet       | StatefulSet | required |
| **MATLAB**  | Interactive MATLAB instances via `matlab-proxy` (browser) | Deployment  | optional |
| **Simulink**| MATLAB instances dedicated to Simulink models             | Deployment  | optional |

Each component can be independently enabled, scaled, and tuned. They share
global GPU scheduling and MathWorks license configuration so the suite deploys
as one unit.

---

## 1. Prerequisites

- **Kubernetes 1.23+** and **Helm 3**.
- For GPU: a GPU node pool with the
  [NVIDIA device plugin](https://github.com/NVIDIA/k8s-device-plugin)
  (or another vendor's plugin — set `global.gpu.resourceName`). For the NVIDIA
  container runtime via `RuntimeClass`, set `global.gpu.runtimeClassName`.
- For MATLAB/Simulink: a reachable MathWorks Network License Manager and
  acceptance of the MathWorks license agreement.
- A **Gazebo image** you control (see the caveat in §5) — there is no public
  "Harmonic" image on Docker Hub.

---

## 2. Quick start

### Gazebo only (no MathWorks license needed)

```bash
helm install sims ./charts/pergola-sim-suite \
  --set matlab.enabled=false \
  --set simulink.enabled=false \
  --set gazebo.image.repository=YOUR_REGISTRY/gazebo \
  --set gazebo.image.tag=YOUR_TAG
```

### Full suite

```bash
helm install sims ./charts/pergola-sim-suite \
  --set global.mathworks.acceptLicense=true \
  --set global.mathworks.licenseServer="27000@license.example.com" \
  --set gazebo.image.repository=YOUR_REGISTRY/gazebo \
  --set gazebo.image.tag=YOUR_TAG
```

> MATLAB and Simulink **refuse to render** unless
> `global.mathworks.acceptLicense=true` **and** a license source
> (`licenseServer` or `licenseFileSecret`) is set — a deliberate safety guard.

For anything beyond a couple of flags, write a values file and use `-f`:

```bash
helm install sims ./charts/pergola-sim-suite -f my-values.yaml
```

---

## 3. Configuration reference

### GPU (`global.gpu`)

| Key                | Default          | Notes                                             |
|--------------------|------------------|---------------------------------------------------|
| `resourceName`     | `nvidia.com/gpu` | Resource key advertised by your device plugin.    |
| `runtimeClassName` | `""`             | e.g. `nvidia` for containerd RuntimeClass.        |
| `nodeSelector`     | `{}`             | Applied to every GPU-requesting pod.              |
| `tolerations`      | `[]`             | To land on tainted GPU nodes.                     |

A component requests a GPU only when its own `gpu.enabled` is true. Gazebo
defaults to on; MATLAB and Simulink default to off.

### MathWorks license (`global.mathworks`)

| Key                 | Default | Notes                                         |
|---------------------|---------|-----------------------------------------------|
| `licenseServer`     | `""`    | `port@host` for the Network License Manager.  |
| `licenseFileSecret` | `""`    | Alternative: Secret holding `license.lic`.    |
| `acceptLicense`     | `false` | Must be `true` to deploy MATLAB/Simulink.     |

### Per-component highlights

- **Gazebo** (`gazebo.*`): `replicaCount` sizes the fleet; each pod gets a
  stable DNS name via the headless service. `world` and `extraArgs` configure
  the sim. Browser visualization comes from the `novnc` sidecar. **Set
  `gazebo.image`** (see §5).
- **MATLAB** (`matlab.*`): `replicaCount` interactive instances; `service.port`
  (8888) serves `matlab-proxy`. Persistent home directory via `persistence`.
- **Simulink** (`simulink.*`): headless batch runners by default
  (`batchModel` sets the MATLAB statement). Set `interactive: true` to expose a
  browser session like MATLAB. With `replicaCount > 1`, keep
  `persistence.enabled: false` or use a `ReadWriteMany` storage class.

---

## 4. Access

Enable the bundled ingress to front the browser-facing components on one host:

```yaml
ingress:
  enabled: true
  className: nginx
  host: sims.example.com
```

This routes `/matlab`, `/simulink` (when interactive), and `/gazebo` (noVNC).
Without ingress, use `kubectl port-forward` against the component services:

```bash
kubectl port-forward svc/sims-matlab 8888:8888
kubectl port-forward svc/sims-gazebo 8080:8080   # noVNC
```

---

## 5. The Gazebo image (important)

The chart's default `gazebo.image` tag (`gazebo:harmonic`) is a **placeholder
and does not exist on Docker Hub**. The official `gazebo` repo only publishes
*classic* Gazebo (`gzserver11`, `libgazebo11`, …) — not modern Gazebo
"Harmonic". GPU-accelerated Gazebo is normally a **custom build** (your robot
models + NVIDIA GL libraries), so point `gazebo.image` at your own image.

The chart's container command assumes modern `gz sim`. If you instead use
classic Gazebo, override the command accordingly.

---

## 6. Testing without a GPU

You can validate the chart and that the images boot on a CPU-only cluster
(kind / minikube / Docker Desktop). With `gazebo.gpu.enabled=false` the chart
drops the GPU resource request and Gazebo falls back to software rendering
(LLVMpipe) — fine for a smoke test, not for production.

```bash
# 1. lint + render (no cluster needed)
helm lint ./charts/pergola-sim-suite
helm template t ./charts/pergola-sim-suite \
  --set global.mathworks.acceptLicense=true \
  --set global.mathworks.licenseServer=27000@dummy \
  --set gazebo.gpu.enabled=false

# 2. deploy to a local cluster
kind create cluster
helm install sims ./charts/pergola-sim-suite \
  --set global.mathworks.acceptLicense=true \
  --set global.mathworks.licenseServer=27000@dummy \
  --set gazebo.gpu.enabled=false --set gazebo.persistence.enabled=false \
  --set matlab.gpu.enabled=false --set matlab.persistence.enabled=false

kubectl get pods -w
helm test sims          # TCP/HTTP reachability checks per component
```

Notes from a verified kind run:
- MATLAB and Simulink images **boot**; MATLAB reaches `Running`. Without a real
  license, Simulink's `matlab -batch` exits (CrashLoopBackOff) — expected.
- The noVNC sidecar runs; only the Gazebo image reference needs supplying.
- **Run native Linux, not Docker Desktop on Apple Silicon** — Docker Desktop
  pulls the amd64 kind node and emulates it, which breaks containerd seccomp
  detection and the control plane never goes healthy.

---

## 7. Uninstall

```bash
helm uninstall sims
# PVCs are retained by default; delete them explicitly if desired:
kubectl delete pvc -l app.kubernetes.io/part-of=pergola-sim-suite
```

---

## 8. Layout

```
pergola-sim-suite/                      # repo root
├── LICENSE
├── README.md                           # repo landing + install instructions
├── USAGE.md                            # this guide
├── .gitignore
├── .github/
│   ├── ct.yaml                         # chart-testing config
│   └── workflows/
│       ├── lint-test.yaml              # ct lint on PRs
│       └── release.yaml                # chart-releaser → gh-pages
└── charts/
    └── pergola-sim-suite/              # the Helm chart
        ├── Chart.yaml
        ├── values.yaml
        ├── README.md                   # chart-level reference
        ├── examples/
        │   ├── production-values.yaml
        │   └── no-gpu-values.yaml
        └── templates/
            ├── _helpers.tpl
            ├── NOTES.txt
            ├── common/    (_gpu.tpl, _mathworks.tpl, ingress.yaml)
            ├── gazebo/    (statefulset.yaml, service.yaml)
            ├── matlab/    (deployment.yaml, service.yaml, pvc.yaml)
            ├── simulink/  (deployment.yaml, service.yaml, pvc.yaml)
            └── tests/     (test-connections.yaml)
```
