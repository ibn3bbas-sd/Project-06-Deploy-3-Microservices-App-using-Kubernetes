import React from 'react';
import { Database, Lock, Image, Server, Shield, Activity, Bell, Globe } from 'lucide-react';

export default function ArchitectureDiagram() {
  return (
    <div className="w-full h-screen bg-slate-900 p-8 overflow-auto">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-white mb-8 text-center">
          Kubernetes Microservices Architecture
        </h1>
        
        {/* External Layer */}
        <div className="mb-8 p-6 bg-slate-800 rounded-lg border-2 border-blue-500">
          <h2 className="text-xl font-semibold text-blue-400 mb-4 flex items-center gap-2">
            <Globe className="w-6 h-6" />
            External Layer
          </h2>
          <div className="flex justify-around items-center flex-wrap gap-4">
            <div className="bg-blue-600 p-4 rounded-lg text-white text-center">
              <Globe className="w-8 h-8 mx-auto mb-2" />
              <div className="font-semibold">Internet</div>
              <div className="text-xs">HTTPS Traffic</div>
            </div>
            <div className="text-white text-2xl">→</div>
            <div className="bg-green-600 p-4 rounded-lg text-white text-center">
              <Shield className="w-8 h-8 mx-auto mb-2" />
              <div className="font-semibold">Ingress Controller</div>
              <div className="text-xs">TLS Termination</div>
              <div className="text-xs">Let's Encrypt</div>
            </div>
          </div>
        </div>

        {/* Kubernetes Cluster */}
        <div className="p-6 bg-slate-800 rounded-lg border-2 border-purple-500">
          <h2 className="text-xl font-semibold text-purple-400 mb-6 flex items-center gap-2">
            <Server className="w-6 h-6" />
            Kubernetes Cluster
          </h2>
          
          {/* Namespaces */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
            {/* Primary API Namespace */}
            <div className="bg-slate-700 p-4 rounded-lg border border-yellow-500">
              <h3 className="text-lg font-semibold text-yellow-400 mb-3">
                Namespace: api-service
              </h3>
              <div className="space-y-3">
                <div className="bg-yellow-600 p-3 rounded text-white">
                  <div className="font-semibold flex items-center gap-2">
                    <Server className="w-5 h-5" />
                    Primary API
                  </div>
                  <div className="text-xs mt-1">Node.js / Express</div>
                  <div className="text-xs">Port: 3000</div>
                  <div className="text-xs">Replicas: 3-10</div>
                </div>
                <div className="bg-slate-600 p-2 rounded text-white text-xs">
                  <div className="font-semibold">Service: ClusterIP</div>
                  <div>api-service:3000</div>
                </div>
                <div className="bg-slate-600 p-2 rounded text-white text-xs">
                  <div className="font-semibold">HPA Enabled</div>
                  <div>CPU: 70% | Memory: 80%</div>
                </div>
              </div>
            </div>

            {/* Auth Service Namespace */}
            <div className="bg-slate-700 p-4 rounded-lg border border-red-500">
              <h3 className="text-lg font-semibold text-red-400 mb-3">
                Namespace: auth-service
              </h3>
              <div className="space-y-3">
                <div className="bg-red-600 p-3 rounded text-white">
                  <div className="font-semibold flex items-center gap-2">
                    <Lock className="w-5 h-5" />
                    Auth Service
                  </div>
                  <div className="text-xs mt-1">Go / Gin</div>
                  <div className="text-xs">Port: 8080</div>
                  <div className="text-xs">Replicas: 2-8</div>
                </div>
                <div className="bg-slate-600 p-2 rounded text-white text-xs">
                  <div className="font-semibold">Service: ClusterIP</div>
                  <div>auth-service:8080</div>
                </div>
                <div className="bg-slate-600 p-2 rounded text-white text-xs">
                  <div className="font-semibold">HPA Enabled</div>
                  <div>CPU: 70% | Requests: 1000/s</div>
                </div>
              </div>
            </div>

            {/* Image Storage Namespace */}
            <div className="bg-slate-700 p-4 rounded-lg border border-green-500">
              <h3 className="text-lg font-semibold text-green-400 mb-3">
                Namespace: image-service
              </h3>
              <div className="space-y-3">
                <div className="bg-green-600 p-3 rounded text-white">
                  <div className="font-semibold flex items-center gap-2">
                    <Image className="w-5 h-5" />
                    Image Storage
                  </div>
                  <div className="text-xs mt-1">Python / FastAPI</div>
                  <div className="text-xs">Port: 8000</div>
                  <div className="text-xs">Replicas: 2-15</div>
                </div>
                <div className="bg-slate-600 p-2 rounded text-white text-xs">
                  <div className="font-semibold">Service: ClusterIP</div>
                  <div>image-service:8000</div>
                </div>
                <div className="bg-slate-600 p-2 rounded text-white text-xs">
                  <div className="font-semibold">HPA Enabled</div>
                  <div>CPU: 75% | Memory: 85%</div>
                </div>
              </div>
            </div>
          </div>

          {/* Supporting Services */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
            {/* Monitoring Stack */}
            <div className="bg-slate-700 p-4 rounded-lg border border-cyan-500">
              <h3 className="text-lg font-semibold text-cyan-400 mb-3 flex items-center gap-2">
                <Activity className="w-5 h-5" />
                Namespace: monitoring
              </h3>
              <div className="space-y-2">
                <div className="bg-cyan-600 p-2 rounded text-white text-sm">
                  Prometheus (Metrics Collection)
                </div>
                <div className="bg-cyan-600 p-2 rounded text-white text-sm">
                  Grafana (Visualization)
                </div>
                <div className="bg-cyan-600 p-2 rounded text-white text-sm flex items-center gap-2">
                  <Bell className="w-4 h-4" />
                  AlertManager (Alerts)
                </div>
              </div>
            </div>

            {/* Data Layer */}
            <div className="bg-slate-700 p-4 rounded-lg border border-orange-500">
              <h3 className="text-lg font-semibold text-orange-400 mb-3 flex items-center gap-2">
                <Database className="w-5 h-5" />
                Data & Storage
              </h3>
              <div className="space-y-2">
                <div className="bg-orange-600 p-2 rounded text-white text-sm">
                  PostgreSQL (StatefulSet)
                </div>
                <div className="bg-orange-600 p-2 rounded text-white text-sm">
                  S3 / MinIO (Object Storage)
                </div>
                <div className="bg-orange-600 p-2 rounded text-white text-sm">
                  Persistent Volumes
                </div>
              </div>
            </div>
          </div>

          {/* Security Layer */}
          <div className="mt-6 bg-slate-700 p-4 rounded-lg border border-pink-500">
            <h3 className="text-lg font-semibold text-pink-400 mb-3 flex items-center gap-2">
              <Shield className="w-5 h-5" />
              Security Components
            </h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div className="bg-pink-600 p-2 rounded text-white text-sm text-center">
                Network Policies
              </div>
              <div className="bg-pink-600 p-2 rounded text-white text-sm text-center">
                Secrets Management
              </div>
              <div className="bg-pink-600 p-2 rounded text-white text-sm text-center">
                RBAC
              </div>
              <div className="bg-pink-600 p-2 rounded text-white text-sm text-center">
                Pod Security
              </div>
            </div>
          </div>
        </div>

        {/* Traffic Flow */}
        <div className="mt-8 p-6 bg-slate-800 rounded-lg border-2 border-indigo-500">
          <h2 className="text-xl font-semibold text-indigo-400 mb-4">
            Traffic Flow & Communication
          </h2>
          <div className="text-white space-y-2 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-blue-500 rounded"></div>
              <span>External → Ingress (HTTPS/TLS) → Primary API</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-yellow-500 rounded"></div>
              <span>Primary API → Auth Service (JWT Validation)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-green-500 rounded"></div>
              <span>Primary API → Image Service (Upload/Retrieve)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-orange-500 rounded"></div>
              <span>All Services → Database (Persistent Data)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-cyan-500 rounded"></div>
              <span>All Services → Prometheus (Metrics Export)</span>
            </div>
          </div>
        </div>

        {/* Legend */}
        <div className="mt-6 p-4 bg-slate-800 rounded-lg">
          <h3 className="text-lg font-semibold text-white mb-3">Legend</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
            <div className="flex items-center gap-2 text-white">
              <div className="w-4 h-4 bg-yellow-500 rounded"></div>
              <span>Node.js Service</span>
            </div>
            <div className="flex items-center gap-2 text-white">
              <div className="w-4 h-4 bg-red-500 rounded"></div>
              <span>Go Service</span>
            </div>
            <div className="flex items-center gap-2 text-white">
              <div className="w-4 h-4 bg-green-500 rounded"></div>
              <span>Python Service</span>
            </div>
            <div className="flex items-center gap-2 text-white">
              <div className="w-4 h-4 bg-cyan-500 rounded"></div>
              <span>Monitoring</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}