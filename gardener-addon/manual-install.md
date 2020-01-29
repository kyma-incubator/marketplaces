# Manually install Kyma on a Gardener Shoot (without using the Addon)

## Prerequisites:

Enable the following extensions for the shoot cluster:
* `shoot-dns-service` extension (adds DNSEntry CRD)
* `shoot-cert-service` extension (adds Certificate CRD)
  
```
spec:
  extensions:
    - type: shoot-dns-service
    - type: shoot-cert-service
```

## Steps
1. Get the shoot domain. If the Nginx Ingress Add-On was activated for the shoot, you will find it in the Gardener UI listed as Ingress domain. Replace the Ingress sub-domain with the Kyma domain: 

```
export DOMAIN="myCluster.myProject.shoot.canary.k8s-hana.ondemand.com"
```

## 2. Deploy the [`Shoot-Cert-Service` extension](https://gardener.cloud/050-tutorials/content/howto/gardener_certificate_management/#extension-installation) to be able to generate the certificate. 
3.  Create the installer Namespace for Kyma and add a new Certificate resource:

```
kubectl create namespace kyma-installer
```
```
cat <<EOF | kubectl apply -f -
apiVersion: cert.gardener.cloud/v1alpha1
kind: Certificate
metadata:
  name: kyma-cert
  namespace: kyma-installer
spec:
  commonName: "*.$DOMAIN"
EOF
```
4. Once the resource gets the status `Ready`, its specification will contain a **spec.secretRef** attribute referencing the generated secret that contains the certificate and the private key. Check the certificate specification: 

```
kubectl -n kyma-installer get certificate kyma-cert -o yaml
```

5. Download the certificate and key. For now, you need to look up the secret name from the Certificate resource as it gets modified.
```
kubectl get -n kyma-installer secret $(kubectl get -n kyma-installer certificate kyma-cert -o jsonpath="{.spec.secretRef.name}") -o jsonpath="{.data['tls\.crt']}" | base64 --decode > tls.crt
kubectl get -n kyma-installer secret $(kubectl get -n kyma-installer certificate kyma-cert -o jsonpath="{.spec.secretRef.name}") -o jsonpath="{.data['tls\.key']}" | base64 --decode > tls.key

export TLS_CERT=$(cat tls.crt | base64 | sed 's/ /\\ /g' | tr -d '\n')
export TLS_KEY=$(cat tls.key | base64 | sed 's/ /\\ /g' | tr -d '\n')
```


6. Create the ConfigMap for custom domain configuration:
```
kubectl create configmap owndomain-overrides -n kyma-installer --from-literal=global.domainName=$DOMAIN --from-literal=global.tlsCrt=$TLS_CERT --from-literal=global.tlsKey=$TLS_KEY \
&& kubectl label configmap owndomain-overrides -n kyma-installer installer=overrides
```

7. Create a ConfigMap for the Istio fix:
```
kubectl create configmap istio-overrides -n kyma-installer --from-literal=global.proxy.includeIPRanges='*' \
&& kubectl label configmap istio-overrides -n kyma-installer installer=overrides  component=istio
```
   
8. Install Tiller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kyma-project/kyma/1.8.0/installation/resources/tiller.yaml
```
For details on installing Kyma with your own domain see [this](https://kyma-project.io/docs/#installation-install-kyma-with-your-own-domain-install-kyma) document.
9. Deploy Kyma-Installer and wait for the process to finish.

```bash
kubectl apply -f https://github.com/kyma-project/kyma/releases/download/1.8.0/kyma-installer-cluster.yaml

while true; do \
  kubectl -n default get installation/kyma-installation -o jsonpath="{'Status: '}{.status.state}{', description: '}{.status.description}"; echo; \
  sleep 5; \
done
```

10. Create the DNS entry using the [`shoot-dns-service` extension](https://gardener.cloud/050-tutorials/content/howto/gardener_dns_management/#configuration). Annotate the `istio-ingressgateway` service with wildcard DNS name: 

```
kubectl -n istio-system annotate service istio-ingressgateway dns.gardener.cloud/class='garden' dns.gardener.cloud/dnsnames='*.'$DOMAIN''
```


11. Construct the URL to access the Kyma console:
```
DOMAIN=$(k -n kyma-installer get configmaps net-global-overrides -o jsonpath="{.data.global\.ingress\.domainName}")
export CONSOLE_URL=https://console.$DOMAIN
```

To retrieve the user name, run:
```
kubectl get secret admin-user -n kyma-system -o jsonpath="{.data.email}" | base64 -D
```
To retrieve the password, run:
```
kubectl get secret admin-user -n kyma-system -o jsonpath="{.data.password}" | base64 -D
```
