# Yellowbook EKS Architecture

This document describes the complete architecture of the Yellowbook application deployed on AWS EKS.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Internet (Users)                          │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         │ HTTPS (443)
                         │
                    ┌────▼────┐
                    │ Route53 │ (DNS Management)
                    │         │ - yellowbook.example.com
                    │         │ - api.yellowbook.example.com
                    └────┬────┘
                         │
                         │ DNS Resolution
                         │
              ┌──────────▼──────────┐
              │ Application Load    │
              │ Balancer (ALB)      │
              │                     │
              │ - SSL/TLS Cert (ACM)│
              │ - HTTP → HTTPS      │
              │ - Health Checks     │
              └──────────┬──────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
        │         Kubernetes              │
        │         Ingress                 │
        │      (AWS LB Controller)        │
        │                                 │
        └────────────────┬────────────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
     ┌──────▼───────┐         ┌───────▼──────┐
     │   Service    │         │   Service    │
     │     (Web)    │         │    (API)     │
     │  ClusterIP   │         │  ClusterIP   │
     └──────┬───────┘         └───────┬──────┘
            │                         │
     ┌──────▼───────┐         ┌───────▼──────┐
     │  Deployment  │         │  Deployment  │
     │   (Web App)  │         │  (API App)   │
     │              │         │              │
     │  Replicas:   │         │  Replicas:   │
     │   2-10 (HPA) │         │   2-10 (HPA) │
     └──────────────┘         └───────┬──────┘
                                      │
                                      │ DB Connection
                                      │
                              ┌───────▼──────┐
                              │   Service    │
                              │ (PostgreSQL) │
                              │  ClusterIP   │
                              └───────┬──────┘
                                      │
                              ┌───────▼──────┐
                              │  Deployment  │
                              │ (PostgreSQL) │
                              │              │
                              │ + PVC (10Gi) │
                              └──────────────┘
```

## Component Details

### 1. External Layer

#### Route53 (DNS)
- Manages domain name resolution
- Automatically updated by External DNS
- Points to ALB hostname
- Records:
  - `A` record: yellowbook.example.com → ALB
  - `A` record: api.yellowbook.example.com → ALB

#### Application Load Balancer (ALB)
- Created by AWS Load Balancer Controller
- SSL/TLS termination using ACM certificate
- HTTP to HTTPS redirect (port 80 → 443)
- Health check configuration
- Target groups for each service
- Routing rules based on hostname

### 2. Kubernetes Cluster (EKS)

#### Ingress
- **Type**: AWS Load Balancer Controller
- **Function**: Routes external traffic to services
- **Features**:
  - Path-based routing
  - Host-based routing
  - TLS termination
  - Health checks
  - ALB annotations

#### Services
- **Type**: ClusterIP (internal)
- **Web Service**: Port 80 → Pods:3000
- **API Service**: Port 80 → Pods:3001
- **PostgreSQL Service**: Port 5432 → Pod:5432

#### Deployments

##### Web Application
- **Image**: yellowbook-web:latest (from ECR)
- **Port**: 3000
- **Replicas**: 2-10 (managed by HPA)
- **Resources**:
  - Requests: 200m CPU, 256Mi memory
  - Limits: 500m CPU, 512Mi memory
- **Health Checks**: HTTP GET /
- **Environment**: ConfigMap + Secrets

##### API Application
- **Image**: yellowbook-api:latest (from ECR)
- **Port**: 3001
- **Replicas**: 2-10 (managed by HPA)
- **Resources**:
  - Requests: 200m CPU, 256Mi memory
  - Limits: 500m CPU, 512Mi memory
- **Health Checks**: HTTP GET /api/health
- **Environment**: ConfigMap + Secrets

##### PostgreSQL Database
- **Image**: postgres:15-alpine
- **Port**: 5432
- **Replicas**: 1 (StatefulSet alternative)
- **Storage**: PersistentVolumeClaim (10Gi, gp2)
- **Resources**:
  - Requests: 250m CPU, 256Mi memory
  - Limits: 500m CPU, 512Mi memory

### 3. Supporting Components

#### Horizontal Pod Autoscaler (HPA)
- Monitors CPU and memory metrics
- Scales deployments automatically
- **API HPA**:
  - Min: 2, Max: 10
  - CPU target: 70%
  - Memory target: 80%
- **Web HPA**:
  - Min: 2, Max: 10
  - CPU target: 70%
  - Memory target: 80%

#### Migration Job
- **Type**: Kubernetes Job
- **Function**: Run database migrations
- **Lifecycle**: 
  1. Wait for PostgreSQL (init container)
  2. Run Prisma migrations
  3. Auto-cleanup (TTL: 300s)

#### ConfigMap
- Non-sensitive configuration
- Environment variables
- API URLs, ports

#### Secret
- Sensitive data (base64 encoded)
- Database credentials
- JWT secrets
- Application secrets

## Data Flow

### 1. User Request Flow (HTTPS)

```
User Browser
    │
    │ 1. DNS Lookup
    ▼
Route53
    │
    │ 2. Returns ALB hostname
    ▼
User Browser
    │
    │ 3. HTTPS request (443)
    ▼
Application Load Balancer
    │
    │ 4. SSL termination
    │ 5. Route based on hostname
    ▼
Kubernetes Ingress
    │
    │ 6. Route to appropriate service
    ▼
ClusterIP Service (Web or API)
    │
    │ 7. Load balance to healthy pods
    ▼
Pod (Web or API)
    │
    │ 8. Process request
    │ 9. Query database if needed
    ▼
PostgreSQL Service → PostgreSQL Pod
    │
    │ 10. Return data
    ▼
Pod processes response
    │
    │ 11. Send response back through chain
    ▼
User Browser (receives response)
```

### 2. Deployment Flow (CI/CD)

```
Developer
    │
    │ 1. git push
    ▼
GitHub Repository
    │
    │ 2. Triggers workflow
    ▼
GitHub Actions
    │
    │ 3. Authenticate via OIDC
    ▼
AWS (assume role)
    │
    │ 4. Get ECR credentials
    ▼
GitHub Actions
    │
    │ 5. Build Docker images
    │ 6. Push to ECR
    ▼
Amazon ECR
    │
    │ 7. Update kubeconfig
    ▼
GitHub Actions
    │
    │ 8. Apply Kubernetes manifests
    ▼
EKS Cluster
    │
    ├─→ 9. Deploy PostgreSQL
    │       │
    │       ▼
    │   Wait for ready
    │       │
    ├─→ 10. Run migration job
    │       │
    │       ▼
    │   Wait for completion
    │       │
    ├─→ 11. Deploy API & Web
    │       │
    │       ▼
    │   Rolling update
    │       │
    └─→ 12. Update Ingress/HPA
            │
            ▼
        Deployment Complete
```

### 3. Auto-Scaling Flow

```
Pod (under load)
    │
    │ 1. CPU/Memory usage increases
    ▼
Metrics Server
    │
    │ 2. Collect metrics
    ▼
HPA Controller
    │
    │ 3. Check against targets
    │    (CPU > 70% or Memory > 80%)
    ▼
Decision: Scale Up
    │
    │ 4. Update Deployment spec
    ▼
Deployment Controller
    │
    │ 5. Create new ReplicaSet
    ▼
ReplicaSet
    │
    │ 6. Create new Pods
    ▼
New Pods (running)
    │
    │ 7. Register with Service
    ▼
Load balanced across all pods
```

## Security Architecture

### Network Security

```
┌─────────────────────────────────────────────────┐
│                  Internet                       │
│            (Untrusted Network)                  │
└────────────────┬────────────────────────────────┘
                 │
                 │ HTTPS only (443)
                 │
    ┌────────────▼────────────┐
    │    AWS WAF (optional)   │
    │  - DDoS protection      │
    │  - Rate limiting        │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │   Application LB        │
    │  - SSL/TLS termination  │
    │  - ACM certificate      │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │      VPC Network        │
    │  - Private subnets      │
    │  - Security groups      │
    │  - Network ACLs         │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │   Kubernetes Services   │
    │  - ClusterIP (internal) │
    │  - No external exposure │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │     Pod Network         │
    │  - CNI (VPC CNI)        │
    │  - Pod security         │
    └─────────────────────────┘
```

### Authentication & Authorization

```
GitHub Actions
    │
    │ 1. Request token from GitHub OIDC
    ▼
GitHub OIDC Provider
    │
    │ 2. Issue JWT token
    ▼
GitHub Actions
    │
    │ 3. Assume role with web identity
    ▼
AWS STS
    │
    │ 4. Validate token
    │ 5. Check trust policy
    ▼
Return temporary credentials
    │
    │ 6. Use credentials
    ▼
AWS Services (ECR, EKS)
    │
    │ 7. Check IAM policies
    ▼
Grant access to resources
```

### Kubernetes RBAC

```
AWS IAM Role
    │
    │ 1. Map to K8s user (aws-auth)
    ▼
Kubernetes User
    │
    │ 2. Check RoleBinding
    ▼
ServiceAccount
    │
    │ 3. Check Role permissions
    ▼
Role (namespace-scoped)
    │
    │ 4. Allow/Deny actions
    ▼
Resource access granted/denied
```

## Monitoring & Observability

### Metrics Collection

```
Application Pods
    │
    │ Expose metrics
    ▼
Metrics Server
    │
    │ Scrape metrics
    ▼
Kubernetes API
    │
    ├─→ HPA (scaling decisions)
    │
    └─→ kubectl top (user queries)
```

### Logging Architecture

```
Application (stdout/stderr)
    │
    ▼
Container Runtime
    │
    ▼
Node's log files
    │
    ├─→ CloudWatch Logs (via log driver)
    │
    └─→ kubectl logs (direct query)
```

### Health Monitoring

```
Pod
    │
    ├─→ Liveness Probe
    │       │
    │       │ Failure → Restart pod
    │       │
    │   Kubelet
    │
    └─→ Readiness Probe
            │
            │ Failure → Remove from service
            │
        Service Endpoints
```

## Disaster Recovery

### Database Backup

```
PostgreSQL Pod
    │
    │ PersistentVolume (EBS)
    ▼
AWS EBS Volume
    │
    ├─→ EBS Snapshots (scheduled)
    │       │
    │       ▼
    │   S3 (snapshot storage)
    │
    └─→ Volume backups (point-in-time)
```

### Application Recovery

```
Pod Failure
    │
    │ Detection (liveness probe)
    ▼
Kubelet
    │
    │ Restart pod
    ▼
New pod from same image
    │
    │ Pull from ECR
    ▼
Pod running again

OR

Node Failure
    │
    │ Detection (node heartbeat)
    ▼
Kubernetes Control Plane
    │
    │ Reschedule pods
    ▼
Pods moved to healthy nodes
```

## Cost Optimization

### Resource Allocation

```
┌─────────────────────────────────────────┐
│           Node Resources                │
│                                         │
│  ┌────────────────────────────────┐   │
│  │     Pod: Web (200m CPU)        │   │
│  └────────────────────────────────┘   │
│  ┌────────────────────────────────┐   │
│  │     Pod: API (200m CPU)        │   │
│  └────────────────────────────────┘   │
│  ┌────────────────────────────────┐   │
│  │     Pod: PostgreSQL (250m CPU) │   │
│  └────────────────────────────────┘   │
│                                         │
│  Total: ~650m CPU minimum               │
│  Node: t3.medium (2 vCPU = 2000m)      │
│  Utilization: ~33% (room for scaling)  │
└─────────────────────────────────────────┘
```

### Auto-Scaling Economics

```
Off-Peak Hours
    │ Low traffic
    │ HPA scales down to minimum (2 replicas each)
    │ Cost: 4 pods + 1 DB = 5 pods total
    ▼
Node Count: 2 nodes (t3.medium)


Peak Hours
    │ High traffic
    │ HPA scales up to maximum (10 replicas each)
    │ Cost: 20 pods + 1 DB = 21 pods total
    ▼
Node Count: ~8 nodes (auto-scaled)
```

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Next.js 15, React, TypeScript | Web application |
| **Backend** | Express, Node.js | API server |
| **Database** | PostgreSQL 15 | Data persistence |
| **ORM** | Prisma | Database access |
| **Container** | Docker | Application packaging |
| **Orchestration** | Kubernetes (EKS) | Container orchestration |
| **Cloud** | AWS | Infrastructure |
| **Load Balancer** | AWS ALB | Traffic distribution |
| **DNS** | Route53 | Domain management |
| **Certificate** | AWS ACM | SSL/TLS certificates |
| **Registry** | Amazon ECR | Container images |
| **CI/CD** | GitHub Actions | Automation |
| **Auth** | AWS IAM + OIDC | Authentication |
| **Monitoring** | Metrics Server | Resource metrics |
| **Scaling** | HPA | Auto-scaling |

## Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Account                          │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │                 VPC (10.0.0.0/16)                  │   │
│  │                                                     │   │
│  │  ┌───────────────────────────────────────────┐    │   │
│  │  │     Public Subnet (10.0.1.0/24)           │    │   │
│  │  │                                            │    │   │
│  │  │  ┌──────────────┐  ┌──────────────┐      │    │   │
│  │  │  │  ALB         │  │  NAT Gateway │      │    │   │
│  │  │  └──────────────┘  └──────────────┘      │    │   │
│  │  │                                            │    │   │
│  │  └───────────────────────────────────────────┘    │   │
│  │                                                     │   │
│  │  ┌───────────────────────────────────────────┐    │   │
│  │  │    Private Subnet (10.0.2.0/24)           │    │   │
│  │  │                                            │    │   │
│  │  │  ┌──────────────┐  ┌──────────────┐      │    │   │
│  │  │  │ EKS Node 1   │  │ EKS Node 2   │      │    │   │
│  │  │  │              │  │              │      │    │   │
│  │  │  │ - Web Pods   │  │ - API Pods   │      │    │   │
│  │  │  │ - API Pods   │  │ - DB Pod     │      │    │   │
│  │  │  └──────────────┘  └──────────────┘      │    │   │
│  │  │                                            │    │   │
│  │  └───────────────────────────────────────────┘    │   │
│  │                                                     │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Internet Gateway
    │
    ▼
Public Subnet (ALB)
    │
    ▼
NAT Gateway
    │
    ▼
Private Subnet (EKS Nodes)
```

---

For detailed deployment instructions, see [DEPLOY.md](DEPLOY.md).

For quick reference, see [QUICKSTART.md](QUICKSTART.md).
