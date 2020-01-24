# Manual Guide to install Kyma on a Gardener Shoot (without using the Addon)

## 1. Prerequisites:

Enable following extensions for the shoot cluster
* `shoot-dns-service` extension (adds DNSEntry CRD)
* `shoot-cert-service` extension (adds Certificate CRD)
  
```
spec:
  extensions:
    - type: shoot-dns-service
    - type: shoot-cert-service
```

## 2. Get the shoot domain
If nginx-ingress addon is activated for the shoot you will find it in the Gardener UI listed as Ingress Domain, replace the ingress sub-domain with "kyma"

```
export DOMAIN="myCluster.myProject.shoot.canary.k8s-hana.ondemand.com"
```

## 3. Generate wildcard certificate via `shoot-cert-service` and download it
Create the installer namespace for Kyma and place a new Certificate resource.

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
After the resource gets status `Ready` it will contain a `spec.secretRef` attribute referencing to the generated secret conatining the certificate and the private key 

```
kubectl -n kyma-installer get certificate kyma-cert -o yaml
```

Download the certificate and key. For now you need to look up the secret name from the certificate resource as it gets modified,
```
kubectl get -n kyma-installer secret $(kubectl get -n kyma-installer certificate kyma-cert -o jsonpath="{.spec.secretRef.name}") -o jsonpath="{.data['tls\.crt']}" | base64 --decode > tls.crt
kubectl get -n kyma-installer secret $(kubectl get -n kyma-installer certificate kyma-cert -o jsonpath="{.spec.secretRef.name}") -o jsonpath="{.data['tls\.key']}" | base64 --decode > tls.key

export TLS_CERT=$(cat tls.crt | base64 | sed 's/ /\\ /g' | tr -d '\n')
export TLS_KEY=$(cat tls.key | base64 | sed 's/ /\\ /g' | tr -d '\n')
```

## 4. Configure kyma-installer

Create configmap for custom domain configuration
```
kubectl create configmap owndomain-overrides -n kyma-installer --from-literal=global.domainName=$DOMAIN --from-literal=global.tlsCrt=$TLS_CERT --from-literal=global.tlsKey=$TLS_KEY \
&& kubectl label configmap owndomain-overrides -n kyma-installer installer=overrides
```

Create configmap for istio fix
```
kubectl create configmap istio-overrides -n kyma-installer --from-literal=global.proxy.includeIPRanges='*' \
&& kubectl label configmap istio-overrides -n kyma-installer installer=overrides  component=istio
```
   
## 5. Install Tiller
See also (https://kyma-project.io/docs/#installation-install-kyma-with-your-own-domain-install-kyma)

```bash
kubectl apply -f https://raw.githubusercontent.com/kyma-project/kyma/1.8.0/installation/resources/tiller.yaml
```

## 6. Deploy Kyma-Installer and wait

```bash
kubectl apply -f https://github.com/kyma-project/kyma/releases/download/1.8.0/kyma-installer-cluster.yaml

while true; do \
  kubectl -n default get installation/kyma-installation -o jsonpath="{'Status: '}{.status.state}{', description: '}{.status.description}"; echo; \
  sleep 5; \
done
```

## 7. Create the DNS entry via `shoot-dns-service`
Annotate istio-ingressgateway service with wildcard DNS name

```
kubectl -n istio-system annotate service istio-ingressgateway dns.gardener.cloud/class='garden' dns.gardener.cloud/dnsnames='*.'$DOMAIN''
```

## 8. You are done

The console URL can be constructed like that:
```
DOMAIN=$(k -n kyma-installer get configmaps net-global-overrides -o jsonpath="{.data.global\.ingress\.domainName}")
export CONSOLE_URL=https://console.$DOMAIN
```

The user name can be retrieved by
```
kubectl get secret admin-user -n kyma-system -o jsonpath="{.data.email}" | base64 -D
```
The password can be retrieved by
```
kubectl get secret admin-user -n kyma-system -o jsonpath="{.data.password}" | base64 -D
```
