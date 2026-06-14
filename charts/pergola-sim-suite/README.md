# pergola-sim-suite

A Helm chart that deploys a GPU-accelerated simulation suite onto Kubernetes as a
single release:

| Component   | What it is                                              | Workload      | GPU         |
|-------------|---------------------------------------------------------|---------------|-------------|
| **Gazebo**  | GPU-accelerated robotics simulators, run as a fleet     | StatefulSet   | required    |
| **MATLAB**  | Interactive MATLAB instances via `matlab-proxy` (browser) | Deployment  | optional    |
| **Simulink**| MATLAB instances dedicated to Simulink models           | Deployment    | optional    |

Each component can be independently enabled, scaled, and tuned. They share global
GPU scheduling and MathWorks license configuration so the suite deploys as one unit.

## Prerequisites

- Kubernetes 1.23+ and Helm 3.
- A GPU node pool with the [NVIDIA device plugin](https://github.com/NVIDIA/k8s-device-plugin)
  (or another vendor's plugin — set `global.gpu.resourceName` accordingly). For the
  NVIDIA container runtime via `RuntimeClass`, set `global.gpu.runtimeClassName`.
- For MATLAB/Simulink: a reachable MathWorks Network License Manager and acceptance
  of the MathWorks license agreement.

## Quick start

Gazebo only (no MathWorks license needed):

```bash
helm install sims ./charts/pergola-sim-suite \
  --set matlab.enabled=false \
  --set simulink.enabled=false
```

Full suite:

```bash
helm install sims ./charts/pergola-sim-suite \
  --set global.mathworks.acceptLicense=true \
  --set global.mathworks.licenseServer="27000@license.example.com"
```

The MATLAB and Simulink components refuse to render unless
`global.mathworks.acceptLicense=true` **and** a license source
(`licenseServer` or `licenseFileSecret`) is set — a deliberate safety guard.

## Key configuration

### GPU (`global.gpu`)

| Key                | Default          | Notes                                              |
|--------------------|------------------|----------------------------------------------------|
| `resourceName`     | `nvidia.com/gpu` | Resource key advertised by your device plugin.     |
| `runtimeClassName` | `""`             | e.g. `nvidia` when using containerd RuntimeClass.  |
| `nodeSelector`     | `{}`             | Applied to every GPU-requesting pod.               |
| `tolerations`      | `[]`             | To land on tainted GPU nodes.                      |

A component requests a GPU only when its own `gpu.enabled` is true. Gazebo defaults
to on; MATLAB and Simulink default to off.

### MathWorks license (`global.mathworks`)

| Key                 | Default | Notes                                          |
|---------------------|---------|------------------------------------------------|
| `licenseServer`     | `""`    | `port@host` for the Network License Manager.   |
| `licenseFileSecret` | `""`    | Alternative: Secret holding `license.lic`.     |
| `acceptLicense`     | `false` | Must be `true` to deploy MATLAB/Simulink.      |

### Per-component highlights

- **Gazebo** (`gazebo.*`): `replicaCount` sizes the fleet; each pod gets a stable
  DNS name via the headless service. `world` and `extraArgs` configure the sim.
  Browser visualization is provided by the `novnc` sidecar.
  > **You must set `gazebo.image`.** The default tag `gazebo:harmonic` is a
  > placeholder and does **not** exist on Docker Hub — the official `gazebo`
  > repo only publishes *classic* Gazebo (`gzserver11`, `libgazebo11`, …), not
  > modern Gazebo "Harmonic". GPU-accelerated Gazebo is normally a custom build
  > (your robot models + NVIDIA GL libraries), so point `gazebo.image` at your
  > own image. The chart's command assumes modern `gz sim`; if you use classic
  > Gazebo, override the container command accordingly.
  > Verified on a kind cluster: the MATLAB and Simulink images deploy and boot;
  > the noVNC sidecar runs; only the Gazebo image reference needs supplying.
- **MATLAB** (`matlab.*`): `replicaCount` interactive instances; `service.port`
  (8888) serves `matlab-proxy`. Persistent home directory via `persistence`.
- **Simulink** (`simulink.*`): headless batch runners by default
  (`batchModel` sets the MATLAB statement). Set `interactive: true` to expose a
  browser session like MATLAB. Note: with `replicaCount > 1`, leave
  `persistence.enabled: false` or use a `ReadWriteMany` storage class.

## Access

Enable the bundled ingress to front the browser-facing components on one host:

```yaml
ingress:
  enabled: true
  className: nginx
  host: sims.example.com
```

This routes `/matlab`, `/simulink` (when interactive), and `/gazebo` (noVNC).
Without ingress, use `kubectl port-forward` against the component services.

## Validate locally

```bash
helm lint ./charts/pergola-sim-suite
helm template sims ./charts/pergola-sim-suite \
  --set global.mathworks.acceptLicense=true \
  --set global.mathworks.licenseServer="27000@host"
```

See `examples/production-values.yaml` for a fuller, cluster-ready configuration.
