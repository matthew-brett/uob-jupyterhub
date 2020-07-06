# Reset secret, autohttps
# See:
# https://discourse.jupyter.org/t/trouble-getting-https-letsencrypt-working-with-0-9-0-beta-4/3583/5?u=matthew.brett
kubectl delete secret $(kubectl get secrets -o custom-columns=SECRET:metadata.name | grep "proxy-.*-tls-acme")
kubectl delete pods $(kubectl get pods -o custom-columns=POD:metadata.name | grep autohttps-)
